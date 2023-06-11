$paths = @(
    "$env:USERPROFILE\gdrive\bin"
    "C:\Program Files\nodejs"
)

foreach ($path in $paths) {
    if ($env:PATH -notlike "*$path*") {
        [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$path", "User")
    }
}
