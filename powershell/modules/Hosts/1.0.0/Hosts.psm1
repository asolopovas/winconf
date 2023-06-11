$PathFile = "$($Env:SystemRoot)\system32\drivers\etc\hosts"

Function Get-HostnameValidation {
    Param(
        [String][Parameter(Mandatory = $True)] $Hostname
    )
    Return [Uri]::CheckHostname($Hostname) -eq [UriHostnameType]::Dns
}

Function New-HostnameMapping {
    Param(
        [String][Parameter(Mandatory = $True)][ValidateScript({Get-HostnameValidation -Hostname $_})] $Hostname,
        [Net.IPAddress] $IPAddress = '127.0.0.1'
    )
    If (-Not (Get-HostnameMapping -Hostname $Hostname -IPAddress $IPAddress)) {
        If (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Add-Content -Path $PathFile -Value "$IPAddress`t$Hostname"
        } Else {
            Start-Process -FilePath PowerShell -WindowStyle Hidden  -Verb RunAs -ArgumentList "-Command New-HostnameMapping -Hostname $Hostname -IPAddress $IPAddress"
        }
    }
}

Function Get-HostnameMapping {
    Param(
        [String][ValidateScript({Get-HostnameValidation -Hostname $_})] $Hostname,
        [Net.IPAddress] $IPAddress
    )
    If ($IPAddress) { $MatchFirst = $IPAddress } Else { $MatchFirst = '[\d\.:]+' }
    If ($Hostname) { $MatchSecond = $Hostname } Else { $MatchSecond = '\S+' }
    $Addresses = Get-Content -Path $PathFile | Select-String -Pattern "^\s*($MatchFirst)\s+($MatchSecond)\s*$"
    ForEach ($Address in $Addresses.Matches) {
        If ($Address) {
            @{ $Address.Groups[2].Value = $Address.Groups[1].Value }
        }
    }
}

Function Set-HostnameMapping {
    Param(
        [String][Parameter(Mandatory = $True)][ValidateScript({Get-HostnameValidation -Hostname $_})] $Hostname,
        [String][ValidateScript({Get-HostnameValidation -Hostname $_})] $NewHostname,
        [Net.IPAddress] $NewIPAddress
    )
    $Address = Get-Content -Path $PathFile | Select-String -Pattern "^\s*([\d\.:]+)\s+$Hostname\s*$"
    If ($Address.Matches) {
        If (-Not $NewHostname) { $NewHostname = $Hostname }
        If (-Not $NewIPAddress) { $NewIPAddress = $Address.Matches.Groups[1].Value }
        If (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            $Content = (Get-Content -Path $PathFile) -Replace "^\s*[\d\.:]+\s+$Hostname\s*$", "$NewIPAddress`t$NewHostname"
            Set-Content -Path $PathFile -Value $Content
        } Else {
            Start-Process -FilePath PowerShell -WindowStyle Hidden -Verb RunAs -ArgumentList "-Command Set-HostnameMapping -Hostname $Hostname -NewHostname $NewHostname -NewIPAddress $NewIPAddress"
        }
    }
}

Function Remove-HostnameMapping {
    Param(
        [String][Parameter(Mandatory = $True)][ValidateScript({Get-HostnameValidation -Hostname $_})] $Hostname
    )
    If (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $Content = Get-Content -Path $PathFile | Where-Object { $_ -NotMatch "^\s*[\d\.:]+\s+$Hostname\s*$" }
        Set-Content -Path $PathFile -Value $Content
    } Else {
        Start-Process -FilePath PowerShell -WindowStyle Hidden  -Verb RunAs -ArgumentList "-Command Remove-HostnameMapping -Hostname $Hostname"
    }
}
