[Reflection.Assembly]::LoadWithPartialName("System.Web")

$fonts = @(
    "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraMono/Regular/FiraMonoNerdFontMono-Regular.otf"
)

Function Install-NerdFont {
    param (
        [parameter(Mandatory = $true)]
        [string]$FontURL
    )
    $FileName = [System.Web.HttpUtility]::UrlDecode($FontURL.Split("/")[-1])
    $FontFile = Join-Path (Get-Location) $FileName
    Invoke-WebRequest -Uri $FontURL -OutFile $FontFile
    $Destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
    $Destination.CopyHere($FontFile, 0x10)
    Remove-Item $FontFile -Force
}

$fonts | ForEach-Object { Install-NerdFont -FontURL $_ }
