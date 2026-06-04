[CmdletBinding()]
param(
    [string]$Release = $env:CODEX_RELEASE
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$installerUri = 'https://chatgpt.com/codex/install.ps1'
$defaultBin = Join-Path $env:LOCALAPPDATA 'Programs\OpenAI\Codex\bin'
$installerPath = Join-Path $env:TEMP 'codex-install.ps1'

function Test-PathEntry {
    param(
        [string]$PathValue,
        [string]$Entry
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) { return $false }
    $needle = $Entry.TrimEnd('\')
    foreach ($part in $PathValue.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)) {
        if ($part.TrimEnd('\') -ieq $needle) { return $true }
    }
    return $false
}

function Prepend-PathEntry {
    param(
        [string]$PathValue,
        [string]$Entry
    )

    $needle = $Entry.TrimEnd('\')
    $parts = [System.Collections.Generic.List[string]]::new()
    [void]$parts.Add($Entry)
    if (-not [string]::IsNullOrWhiteSpace($PathValue)) {
        foreach ($part in $PathValue.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)) {
            if ($part.TrimEnd('\') -ine $needle) { [void]$parts.Add($part) }
        }
    }
    return ($parts -join ';')
}

function Set-DefaultCodexPath {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not (Test-PathEntry -PathValue $userPath -Entry $defaultBin)) {
        [Environment]::SetEnvironmentVariable('Path', (Prepend-PathEntry -PathValue $userPath -Entry $defaultBin), 'User')
    }

    if (-not (Test-PathEntry -PathValue $env:Path -Entry $defaultBin)) {
        $env:Path = Prepend-PathEntry -PathValue $env:Path -Entry $defaultBin
    }
}

$oldNonInteractive = $env:CODEX_NON_INTERACTIVE
$oldInstallDir = $env:CODEX_INSTALL_DIR
try {
    $env:CODEX_NON_INTERACTIVE = '1'
    Remove-Item Env:\CODEX_INSTALL_DIR -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri $installerUri -OutFile $installerPath -UseBasicParsing
    if ([string]::IsNullOrWhiteSpace($Release)) {
        & $installerPath
    } else {
        & $installerPath -Release $Release
    }
    if ($LASTEXITCODE -ne 0) { throw "Codex installer failed with exit code $LASTEXITCODE" }
} finally {
    if ($null -eq $oldNonInteractive) { Remove-Item Env:\CODEX_NON_INTERACTIVE -ErrorAction SilentlyContinue } else { $env:CODEX_NON_INTERACTIVE = $oldNonInteractive }
    if ($null -eq $oldInstallDir) { Remove-Item Env:\CODEX_INSTALL_DIR -ErrorAction SilentlyContinue } else { $env:CODEX_INSTALL_DIR = $oldInstallDir }
    Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
}

Set-DefaultCodexPath
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
Set-DefaultCodexPath

$codex = Get-Command codex -CommandType Application -ErrorAction Stop
if (-not $codex.Source.StartsWith($defaultBin, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "codex resolved to '$($codex.Source)' instead of '$defaultBin'. Check PATH order."
}

& $codex.Source --version
if ($LASTEXITCODE -ne 0) { throw "codex verification failed with exit code $LASTEXITCODE" }
Write-Host "Codex available at $($codex.Source)" -ForegroundColor Green
