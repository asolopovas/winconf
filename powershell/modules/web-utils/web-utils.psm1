
. $PSScriptRoot\ssl.ps1

function Etc-Hosts($host, [switch]$remove = $false) {
  $hostPath = "C:\Windows\System32\Drivers\etc\hosts"
  $hosts = Get-Content $hostPath
  if ($hosts) {
    if ($remove -And [Regex]::IsMatch($hosts, "127.0.0.1 $host")) {
      $hosts |  Where-Object {$_ -notmatch "127.0.0.1 $host"} | Set-Content $hostPath
    }

    if (!($hosts) -Or ![Regex]::IsMatch($hosts, "127.0.0.1 $host")) {
      Add-Content $hostPath "`n127.0.0.1 $host"
    }
  }
}

function Prompt-User($title, $message) {
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    return ![bool]$host.ui.PromptForChoice($title, $message, $options, 0)
}

function Prompt-Del-Existing-Dir($path) {
 Push-Location $dev_root
  if (Test-Path $path) {
    $title = "Directory $path is about to be deleted"
    $message = "$path Do you want to delete the folder?"
    $result = Prompt-User $title $message
    if ($result) {
        Remove-Item $path -Recurse
        return [bool]1
    } else {
        Pop-Location
        return [bool]0
    }
  }
}

function Site-Root-Name($name) {
  if ($name -match '(.*?(?=\.\w{2,10}(\.\w{2,10})?$))') {
    return $matches[1]
  }
}

function IIS-Install($phpPath = $php_location) {
  $features = @(
    'IIS-WebServerRole',
    'IIS-CGI',
    'IIS-WebServerManagementTools',
    'IIS-HttpCompressionDynamic',
    'IIS-RequestMonitor',
    'IIS-ManagementScriptingTools'
  )

  Feature-Enable($features)

  copy "$dev_configs\php\php.ini" $phpPath
  $phpCgi = $phpPath + "\php-cgi.exe"
  $phpIni = $phpPath + "\php.ini"
  $configPath = "system.webServer/fastCgi/application[@fullPath='$phpCgi']"
  Set-WebConfigurationProperty -filter /system.webServer/directoryBrowse -name enabled  -Value 'True' -PSPath 'IIS:\'
  if (!(Get-WebConfiguration "//defaultDocument/files/*" | where {$_.value -eq "index.php"})) {
    Add-WebConfiguration -Filter "//defaultDocument/files" -PSPath "IIS:\" -AtIndex 0 -Value @{value = "index.php"}
  }

  if (Get-WebHandler -Name "PHP7_over_FastCGI") {
    Set-WebHandler -Name "PHP7_over_FastCGI" -Path "*.php" -Modules FastCgiModule -PSPath "IIS:\" -ScriptProcessor $phpCgi -Verb "*"
  }
  else {
    New-WebHandler -Name "PHP7_over_FastCGI" -Path "*.php" -Modules FastCgiModule -PSPath "IIS:\" -ScriptProcessor $phpCgi -Verb "*"
  }
  ###############################################################
  # Configure the FastCGI Setting
  ###############################################################
  # Set the max request environment variable for PHP


  if (Get-WebConfiguration system.webServer/fastCgi/application | where {$_.fullPath -like "*php-cgi.exe"}) {
    Write-Output "Changing FastCgi configuration ...."
    Set-WebConfiguration  'system.webServer/fastCgi/application' -value @{'fullPath' = $phpCgi}
  }
  else {
    Write-Output "Adding FastCgi configuration ...."
    Add-WebConfiguration 'system.webServer/fastCgi' -value @{'fullPath' = $phpCgi}

  }
  # Configure the settings
  # Available settings:
  #     instanceMaxRequests, monitorChangesTo, stderrMode, signalBeforeTerminateSeconds
  #     activityTimeout, requestTimeout, queueLength, rapidFailsPerMinute,
  #     flushNamedPipe, protocol
  Set-WebConfigurationProperty $configPath -Name instanceMaxRequests -Value 10000
  Set-WebConfigurationProperty $configPath -Name monitorChangesTo -Value $phpIni
  # Restart IIS to load new configs.
  invoke-command -scriptblock {iisreset /restart }
  # Add-WebConfigurationProperty //staticContent -name collection -value @{fileExtension='.webmanifest'; mimeType='application/manifest+json'}
  # Add-WebConfigurationProperty //staticContent -name collection -value @{fileExtension='.webp'; mimeType='image/webp'}
  choco install -y urlrewrite
}

function IIS-Host-Remove([parameter(Mandatory = $true)]$hostname, [switch]$wp) {
  if (Test-Path IIS:\AppPools\$hostname) {
    Remove-WebAppPool -Name $hostname
  }

  if (Test-Path IIS:\Sites\$hostname) {
    Remove-Website -Name $hostname
  }

  Get-ChildItem IIS:\SslBindings | Where-Object { $_.Host -eq $hostname }| Remove-Item
  Etc-Hosts $hostname -remove

  if ($wp) {
    $host_root_name = Site-Root-Name $hostname
    $db = "$host_root_name" + "_wp"
    Mysql-RemoveDB $db
  }

  if (Test-Path "$dev_root\$hostname") {
    $result = Prompt-User "Folder $dev_root\$hostname exist" "Would you like to delete it?"
    if ($result) {
       Remove-Item -Recurse "$dev_root\$hostname"
    }
  }


}

function IIS-Host-Add($hostname, [switch]$laravel) {
  $iisAppPoolName = $hostname
  $siteNameWithoutExtension = Site-Root-Name $iisAppPoolName
  $iisAppName = $siteNameWithoutExtension + ".test"

  if ($laravel) {
    $directoryPath = "$dev_root\$hostname\public"
    copy "$dev_configs\IIS\laravel-web.config" "$directoryPath\web.config"
  } else {
    $directoryPath = "$dev_root\$hostname"
    copy "$dev_configs\IIS\wp-web.config" "$directoryPath\web.config"
  }

  Etc-Hosts $iisAppName

  Push-Location IIS:\AppPools\
    #check if the app pool exists
    if (!(Test-Path $iisAppPoolName -pathType container)) {
      #create the app pool
      $appPool = New-Item $iisAppPoolName
    }
  Pop-Location

  Push-Location IIS:\Sites\
    #check if the site exists
    if (Test-Path $iisAppPoolName -pathType container) {
      Pop-Location
      return
    }

    # #create the site
    $iisApp = New-Item $iisAppPoolName -bindings @{protocol = "http"; bindingInformation = ":80:" + $iisAppName} -physicalPath $directoryPath
    $iisApp | Set-ItemProperty -Name "applicationPool" -Value $iisAppPoolName
  Pop-Location

}

function IIS-HostBinding($hostname) {
  $storeLocation = "Cert:\LocalMachine\WebHosting"
  if (!(Certificate-Exist $hostname)) {
    $certObj = Import-PfxCertificate -FilePath "$dev_host_cert\$hostname.pfx" -CertStoreLocation $storeLocation
  } else {
    $certObj = Get-ChildItem $storeLocation | Where-Object { $_.Subject -Match $hostname }
  }

  $cert = $certObj.Thumbprint
  $guid = [guid]::NewGuid().ToString("B")

  if ($null -eq (get-webbinding | where-object {$_.bindinginformation -eq "*:443:$hostname"})) {
    netsh http add sslcert hostnameport="${hostname}:443" certhash="$cert" certstorename=WebHosting appid="$guid"
    New-WebBinding -Name $hostname -Protocol https -IPAddress "*" -HostHeader $hostname -Port 443 -SslFlags 1
  }
}

. $PSScriptRoot\mysql.ps1
. $PSScriptRoot\wordpress.ps1
. $PSScriptRoot\phpmyadmin.ps1
. $PSScriptRoot\laravel.ps1

Export-ModuleMember -Function * -Alias *
