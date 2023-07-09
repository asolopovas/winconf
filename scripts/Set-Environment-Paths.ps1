$paths = @(
    "C:\Users\Andrius\AppData\Local\Microsoft\WinGet\Links"
    "C:\Program Files\starship\bin\"

)

foreach ($path in $paths) {
    if ($env:PATH -notlike "*$path*") {
        [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$path", "User")
    }
}
