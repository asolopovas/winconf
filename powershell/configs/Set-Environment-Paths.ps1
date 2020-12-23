$paths = @(
    "$HOME\Google Drive\bin"
)

foreach ($path in $paths) {
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$path", "User")
}
