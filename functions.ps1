function Add-Capability {
    param([Parameter(Mandatory = $true)] [string] $name)
    Add-WindowsCapability -Online -Name $name
}

function Test-ReparsePoint([string]$path) {
    $file = Get-Item $path -Force -ea SilentlyContinue
    return [bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Test-CommandExists {
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "stop"

    try { if (Get-Command $command) { return $true } }
    Catch { return $false }
    Finally { $ErrorActionPreference = $oldPreference }
}

function SetPermissions($dir) {
    $acl = Get-Acl $dir
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:UserName", "FullControl", "Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl $dir $acl
}

function CreateSymLink($src, $target) {
    Remove-Item -Force -Recurse -Confirm:$false $src -ErrorAction SilentlyContinue
    New-Item -ItemType SymbolicLink -Path $src -Target $target -Force
}

function RestartExplorer {
    Stop-Process -Name explorer -Force
    Start-Process explorer.exe
}

function Clear-DebugLogs {
    param(
        [string]$LogDirectory = "$env:userprofile\winconf\logs"
    )
    
    if (Test-Path $LogDirectory) {
        Get-ChildItem -Path $LogDirectory -Filter "*.log" -File | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "Debug logs cleared from: $LogDirectory" -ForegroundColor Green
    } else {
        Write-Host "Log directory not found: $LogDirectory" -ForegroundColor Yellow
    }
}
