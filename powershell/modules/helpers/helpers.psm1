
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

function keyboardLayoutSetup {
    Set-ItemProperty -Path "HKCU:\Keyboard Layout\Preload" -Name "1" -Value "00000809"
    Set-ItemProperty -Path "HKCU:\Keyboard Layout\Preload" -Name "2" -Value "00000419"
    Set-ItemProperty -Path "HKCU:\Keyboard Layout\ShowToast" -Name "Show" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKCU:\Keyboard Layout\Substitutes" -Name "00000409" -Value "00000809"
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

    if (-not (Test-Path $FileToCheck)) {
        throw "File $FileToCheck does not exist."
    }

    Write-Host "Checking hash for file: $FileToCheck"
    Write-Host "Provided hash: $providedHash"

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.IO.File]::ReadAllBytes($FileToCheck)
    $calculatedHash = -join ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString("X2") })

    Write-Host "Calculated hash: $calculatedHash"

    if ($calculatedHash -eq $providedHash.ToUpper()) {
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

. $PSScriptRoot\convertions.ps1
. $PSScriptRoot\docker-compose.ps1
. $PSScriptRoot\files.ps1
. $PSScriptRoot\firewall-blocker.ps1
. $PSScriptRoot\rm-pattern.ps1
. $PSScriptRoot\security.ps1
. $PSScriptRoot\system.ps1
. $PSScriptRoot\tools.ps1
. $PSScriptRoot\wsl.ps1
