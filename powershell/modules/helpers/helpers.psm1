
function Get-RootName($name) {
    return [io.path]::GetFileNameWithoutExtension($name)
}

function IIf($If, $Then, $Else) {
    If ($If -IsNot "Boolean") { $_ = $If }
    If ($If) { If ($Then -is "ScriptBlock") { &$Then } Else { $Then } }
    Else { If ($Else -is "ScriptBlock") { &$Else } Else { $Else } }
}

function UpdateModuleManifest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$moduleManifestPath
    )

    $directoryPath = Split-Path -Path $moduleManifestPath
    $files = Get-ChildItem -Path $directoryPath -Recurse | Where-Object { $_.Extension -eq '.ps1' -or $_.Extension -eq '.psm1' }

    $functionsExport = @()
    $loopEnd = $files[-1]
    foreach ($file in $files) {
        $functionNames = Select-String -Path $file.FullName -Pattern 'function ([\w-]+)' | ForEach-Object {
            "        '" + $_.Matches[0].Groups[1].Value + "',"
        }

        if ($file -eq $loopEnd) {
            $el = $functionNames[-1].TrimEnd(',')
            $functionNames[-1] = $el
        }
        $functionsExport += "        # " + $file.Name
        $functionsExport += $functionNames
    }


    $moduleManifest = Get-Content -Path $moduleManifestPath

    $startLine = ($moduleManifest | Select-String -Pattern 'FunctionsToExport = @\(').LineNumber
    $endLine = ($moduleManifest | Select-String -Pattern '^\s*\)').LineNumber

    $moduleManifest = $moduleManifest[0..($startLine - 2)] +
    "    FunctionsToExport = @(" +
    $functionsExport +
    "    )" +
    $moduleManifest[($endLine)..($moduleManifest.Length - 1)]

    $moduleManifest | Set-Content -Path $moduleManifestPath
}

function LinuxDriveMounter {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }

    $driveIsMounted = $false

    powershell -Command "wsl --mount \\.\PHYSICALDRIVE2 --bare" 2>&1

    if (-not $driveIsMounted) {
        $password = Read-Host "Enter password" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

        $cmd = "echo '$plainPassword' | cryptsetup luksOpen /dev/sdf3 cryptdata"
        wsl -u root -e bash -c "$cmd"

        wsl -u root -e bash -c "mount -a"

        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        $plainPassword = $null
    }
}

function Remove-CertByName {
    param(
        [Parameter(Mandatory)][string]$Name,
        [ValidateSet("LocalMachine", "CurrentUser")][string]$Scope = "LocalMachine"
    )

    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root", $Scope
    $store.Open("ReadWrite")
    $found = $store.Certificates | Where-Object { $_.Subject -match $Name -or $_.Issuer -match $Name }

    if (-not $found) { Write-Host "No matching certs found."; $store.Close(); return }

    $found | ForEach-Object -Begin { $i=1 } -Process {
        Write-Host "[$i] $($_.Subject)`n    Thumbprint: $($_.Thumbprint)`n    Expires: $($_.NotAfter)`n"
        $i++
    }

    $sel = Read-Host "Enter number to delete (Enter to cancel)"
    if ($sel -as [int] -and $sel -gt 0 -and $sel -le $found.Count) {
        $cert = $found[$sel - 1]
        if ((Read-Host "Delete '$($cert.Subject)'? (Y/N)") -match '^y$') {
            $store.Remove($cert)
            Write-Host "Deleted."
        } else {
            Write-Host "Cancelled."
        }
    } else {
        Write-Host "Cancelled or invalid selection."
    }

    $store.Close()
}

function Register-Cert {
    param(
        [Parameter(Mandatory)][string]$Path,
        [ValidateSet("LocalMachine", "CurrentUser")][string]$Scope = "LocalMachine",
        [ValidateSet("Root", "My", "CA", "AuthRoot")][string]$StoreName = "Root"  # Trusted Root by default
    )

    if (-not (Test-Path $Path)) {
        Write-Error "Certificate file not found at path: $Path"
        return
    }

    try {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cert.Import($Path)

        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($StoreName, $Scope)
        $store.Open("ReadWrite")
        $store.Add($cert)
        Write-Host "Certificate imported successfully:"
        Write-Host "  Subject    : $($cert.Subject)"
        Write-Host "  Thumbprint : $($cert.Thumbprint)"
        Write-Host "  Expires    : $($cert.NotAfter)"
        $store.Close()
    }
    catch {
        Write-Error "Failed to import certificate: $_"
    }
}


function Test-Sha {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ShaOrFilePath,

        [Parameter(Mandatory = $false)]
        [string]$FileToCheck
    )

    $IsUrl = $ShaOrFilePath -match '^https?://'

    if (-not $FileToCheck) {
        if ($IsUrl) {
            $content = Invoke-WebRequest -Uri $ShaOrFilePath -UseBasicParsing | Select-Object -ExpandProperty Content
        }
        elseif (Test-Path $ShaOrFilePath) {
            $content = Get-Content $ShaOrFilePath -Raw
        }
        else {
            throw "File or URL $ShaOrFilePath does not exist."
        }

        $providedHash, $relativeFilePath = $content -split '\s+', 2
        $relativeFilePath = $relativeFilePath.Trim()
        $FileToCheck = Resolve-Path $relativeFilePath
    }
    else {
        if ($IsUrl) {
            $content = Invoke-WebRequest -Uri $ShaOrFilePath -UseBasicParsing | Select-Object -ExpandProperty Content
            $providedHash, $_ = $content -split '\s+', 2
        }
        else {
            $providedHash = if (Test-Path $ShaOrFilePath) { Get-Content $ShaOrFilePath -Raw } else { $ShaOrFilePath }
            $FileToCheck = Resolve-Path $FileToCheck
        }
    }

    $providedHash = $providedHash.Trim().Split(' ')[0] # Extract only the hash part

    if (-not (Test-Path $FileToCheck)) {
        throw "File $FileToCheck does not exist."
    }


    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.IO.File]::ReadAllBytes($FileToCheck)
    $calculatedHash = -join ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString("X2") })

    $calculatedHash = $calculatedHash.ToUpper()
    $providedHash = $providedHash.ToUpper()
    Write-Host "------------------------------------------------------------------------------------"
    Write-Host "$FileToCheck  - File Hash Check"
    Write-Host "$providedHash"
    Write-Host "$ShaOrFilePath - Comparison"
    Write-Host "$calculatedHash"
    Write-Host "------------------------------------------------------------------------------------"

    if ($calculatedHash -eq $providedHash) {
        "Hash matches!"
    }
    else {
        "Hash doesn't match!"
    }
}

function Update-UserPath {
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$Replacements
    )

    # Get the current user PATH
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $paths = $userPath -split ';'

    # Perform search and replace for each section of each path
    $updatedPaths = $paths | ForEach-Object {
        $pathSections = $_ -split '\\'
        $updatedSections = $pathSections | ForEach-Object {
            $currentSection = $_
            foreach ($key in $Replacements.Keys) {
                if ($currentSection -eq $key) {
                    $currentSection = $Replacements[$key]
                }
            }
            $currentSection
        }
        $updatedSections -join '\'
    }

    # Update the user PATH
    $updatedUserPath = ($updatedPaths -join ';')
    [Environment]::SetEnvironmentVariable("PATH", $updatedUserPath, "User")

    Write-Host "User PATH has been updated."
}

. $PSScriptRoot\conversions.ps1
. $PSScriptRoot\docker-compose.ps1
. $PSScriptRoot\edit-hosts.ps1
. $PSScriptRoot\files.ps1
. $PSScriptRoot\firewall-blocker.ps1
. $PSScriptRoot\rm-pattern.ps1
. $PSScriptRoot\security.ps1
. $PSScriptRoot\system.ps1
. $PSScriptRoot\tools.ps1
. $PSScriptRoot\wsl.ps1
