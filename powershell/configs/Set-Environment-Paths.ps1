$paths = @(
    "$HOME\Google Drive\bin"
    "C:\Program Files\nodejs"
)

foreach ($path in $paths) {
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$path", "User")
}
