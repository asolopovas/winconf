$paths = @(
   $env:LOCALAPPDATA + "\Microsoft\WinGet\Links"
    "C:\Program Files\starship\bin\"
    $env:USERPROFILE + "\winconf\bin"
)

foreach ($path in $paths) {
    if ($env:PATH -notlike "*$path*") {
        [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$path", "User")
    }
}
