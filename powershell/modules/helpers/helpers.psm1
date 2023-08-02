
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


. $PSScriptRoot\convertions.ps1
. $PSScriptRoot\docker-compose.ps1
. $PSScriptRoot\files.ps1
. $PSScriptRoot\firewall-blocker.ps1
. $PSScriptRoot\rm-pattern.ps1
. $PSScriptRoot\security.ps1
. $PSScriptRoot\system.ps1
. $PSScriptRoot\tools.ps1
. $PSScriptRoot\wsl.ps1
