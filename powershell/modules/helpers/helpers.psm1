
function Get-RootName($name) {
    return [io.path]::GetFileNameWithoutExtension($name)
}

function IIf($If, $Then, $Else) {
    If ($If -IsNot "Boolean") { $_ = $If }
    If ($If) { If ($Then -is "ScriptBlock") { &$Then } Else { $Then } }
    Else { If ($Else -is "ScriptBlock") { &$Else } Else { $Else } }
}

function ExtractFunctions($filePath) {
    $outputDirectory = Split-Path -Path $filePath
    $fileName = Split-Path -Path $filePath -Leaf
    $outputFileName = [System.IO.Path]::ChangeExtension($fileName, ".txt")
    $outputPath = Join-Path -Path $outputDirectory -ChildPath $outputFileName

    $functionNames = Select-String -Path $filePath -Pattern 'function (\w+)' | ForEach-Object {
        "'" + $_.Matches[0].Groups[1].Value + "',"
    }
    Set-Content -Path $outputPath -Value ("# " + $fileName)
    Add-Content -Path $outputPath -Value $functionNames
}

function ExtractFunctionsInDirectory($directoryPath = $(Get-Location)) {
    $outputPath = Join-Path -Path $directoryPath -ChildPath "functions.txt"
    if (Test-Path $outputPath) {
        Remove-Item -Path $outputPath
    }

    $files = Get-ChildItem -Path $directoryPath -Recurse | Where-Object { $_.Extension -eq '.ps1' -or $_.Extension -eq '.psm1' }

    foreach ($file in $files) {
        $fileName = $file.Name
        $functionNames = Select-String -Path $file.FullName -Pattern 'function (\w+)' | ForEach-Object {
            "'" + $_.Matches[0].Groups[1].Value + "',"
        }
        Add-Content -Path $outputPath -Value ("# " + $fileName)
        Add-Content -Path $outputPath -Value $functionNames
    }
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

. $PSScriptRoot\system.ps1

. $PSScriptRoot\convertions.ps1
. $PSScriptRoot\docker-compose.ps1
. $PSScriptRoot\files.ps1
. $PSScriptRoot\firewall-blocker.ps1
. $PSScriptRoot\rm-pattern.ps1
. $PSScriptRoot\security.ps1
. $PSScriptRoot\system.ps1
. $PSScriptRoot\tools.ps1
. $PSScriptRoot\wsl.ps1
