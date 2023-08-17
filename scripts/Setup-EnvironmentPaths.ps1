# Get the .sys-env file content
# check if exist "../.sys-env"
$path = "../.sys-env"
if (-not (Test-Path -Path $path)) { # Fixed this line
    New-Item -Path $path -ItemType File
}
$paths = Get-Content $path

# Convert PATH to an array for easier manipulation and normalize paths
$currentPaths = $env:Path -split ';' | ForEach-Object { $_.TrimEnd('\').ToLower() }

# Iterate over the paths from the .sys-env file
foreach ($path in $paths) {
    # Expand environment variables in the path
    $expandedPath = $ExecutionContext.InvokeCommand.ExpandString($path)

    # Normalize expanded path
    $normalizedPath = $expandedPath.TrimEnd('\').ToLower()

    if ((Test-Path -Path $expandedPath) -and ($currentPaths -notcontains $normalizedPath)) {
        # Add path to local array
        $currentPaths += $expandedPath
        Write-Host "Adding $expandedPath to System PATH ..."
    }
    else {
        Write-Host "$expandedPath does not exist or is already in PATH..."
    }
}

# Join the array back into a single string and update PATH
$newPath = $currentPaths -join ';'
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")
