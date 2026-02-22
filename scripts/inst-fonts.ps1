Add-Type -AssemblyName System.Web

$fonts = @(
    "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraMono/Regular/FiraMonoNerdFontMono-Regular.otf"
)

$installedFontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$systemFontsDir = "$env:SystemRoot\Fonts"

Function Test-FontInstalled {
    param ([string]$FileName)
    if (Test-Path (Join-Path $installedFontsDir $FileName)) { return $true }
    if (Test-Path (Join-Path $systemFontsDir $FileName)) { return $true }
    return $false
}

Function Install-NerdFont {
    param (
        [parameter(Mandatory = $true)]
        [string]$FontURL
    )
    $FileName = [System.Web.HttpUtility]::UrlDecode($FontURL.Split("/")[-1])

    if (Test-FontInstalled $FileName) {
        Write-Host "  $FileName already installed" -ForegroundColor DarkGray
        return
    }

    Write-Host "  Installing $FileName..." -ForegroundColor Cyan
    $FontFile = Join-Path $env:TEMP $FileName
    Invoke-WebRequest -Uri $FontURL -OutFile $FontFile
    $Destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
    $Destination.CopyHere($FontFile, 0x10)
    Remove-Item $FontFile -Force
    Write-Host "  $FileName installed" -ForegroundColor Green
}

$fonts | ForEach-Object { Install-NerdFont -FontURL $_ }
