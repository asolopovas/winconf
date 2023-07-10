$paths = @(
   $env:LOCALAPPDATA + "\Microsoft\WinGet\Links"
    "C:\Program Files\starship\bin\"
    $env:USERPROFILE + "\winconf\bin"
    $env:USERPROFILE  + "\miniconda3"
)

foreach ($path in $paths) {
    if ($env:PATH -notlike "*$path*") {
        Write-Host "Adding $path to System PATH ..."
        [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$path", "User")
    }
}
