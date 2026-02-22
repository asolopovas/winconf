function clearShellContextMenu {
    param (
        [Parameter(Mandatory = $false)]
        [string[]] $removeRegistryKeys = @(
            "HKCR:\Directory\Background\shell\git_shell",
            "HKCR:\Directory\Background\shell\git_gui",
            "HKCR:\Directory\shell\git_shell",
            "HKCR:\Directory\shell\git_gui",
            "HKCR:\Directory\shell\PlayWithVLC",
            "HKCR:\Directory\shell\AddToPlaylistVLC",
            "HKCR:\Directory\shell\ShareX",
            "HKCR:\Directory\shell\CaptureOne"
        )
    )

    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR

    foreach ($key in $removeRegistryKeys) {
        if (Test-Path $key) {
            Remove-Item -Path $key -Recurse -Force -Verbose
        }
    }
}
function conf {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('push', 'pull')]
        [string]$action
    )

    $paths = @(
        "$env:USERPROFILE\winconf"
    )

    foreach ($path in $paths) {
        if ($action -eq "push") {
            Write-ColorOutput green "Pushing $path ..."
            git -C $path add .
            git -C $path commit -m 'Save'
            git -C $path push
        }
        else {
            Write-ColorOutput green  "Pulling $path ..."
            git -C $path pull
        }
    }
}

function gitRmPreviousCommits {
    $yn = Read-Host -Prompt "This will delete all previous commits in the current repository. Are you sure you want to proceed? (yes/no)"
    switch -Wildcard ($yn) {
        "y*" {
            if (-not (Test-Path .git)) { return }
            $originUrl = git remote get-url origin
            if ([string]::IsNullOrEmpty($originUrl)) { return }
            Remove-Item .git -Recurse -Force
            git init
            git add .
            git commit -m 'initial commit'
            git remote add origin $originUrl
            git branch -M main
            git push --force -u origin main
        }
        "n*" { Write-Output "Exiting..."; exit }
        default { Write-Output "Invalid response."; exit 1 }
    }
}

function sshCopyID($hostname) {
    Get-Content ~/.ssh/id_rsa.pub | ssh $hostname 'Add-Content | Out-File C:\ProgramData\ssh\administrators_authorized_keys; icacls.exe ""$env:ProgramData\ssh\administrators_authorized_keys"" /inheritance:r /grant ""Administrators:F"" /grant ""SYSTEM:F""'
}

function tail($path, [Boolean]$f = $false, [string]$n = 10) {
    if ($f) {
        Get-Content -Path $path -Wait -Tail $n
    }
    else {
        Get-Content -Path $path -Tail $n
    }
}

function Show-EnvironmentPaths {
    $userEnvPaths = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User) -split ';'
    $systemEnvPaths = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine) -split ';'

    Write-Host "Hi Andrew!"

    Write-Host "User Environment Paths:`n" -ForegroundColor Cyan
    foreach ($path in $userEnvPaths) {
        Write-Host " - $path"
    }

    Write-Host "`nSystem Environment Paths:`n" -ForegroundColor Yellow
    foreach ($path in $systemEnvPaths) {
        Write-Host " - $path"
    }
}

