function Test-CommandExists {
    param (
        [Parameter(Mandatory)]
        [string]$Command
    )

    [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Test-RegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Value
    )

    $property = Get-ItemProperty -Path $Path -Name $Value -ErrorAction SilentlyContinue
    return [bool]$property
}

function Test-ScheduledTask {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    [bool](Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue)
}

function global:repo {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    $owner = if ($env:REPO_OWNER) { $env:REPO_OWNER } else { 'asolopovas' }
    $cacheTtl = 21600
    if ($env:REPO_CACHE_TTL) { [void][int]::TryParse($env:REPO_CACHE_TTL, [ref]$cacheTtl) }
    $repoLimit = 1000
    if ($env:REPO_LIMIT) { [void][int]::TryParse($env:REPO_LIMIT, [ref]$repoLimit) }
    $cacheRoot = if ($env:XDG_CACHE_HOME) { $env:XDG_CACHE_HOME } elseif ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'winconf' } else { Join-Path $env:USERPROFILE '.cache' }
    $cacheDir = Join-Path $cacheRoot 'dotfiles'
    $cacheFile = Join-Path $cacheDir "repos-$owner"
    $useHttps = $false
    $pickRepo = $false
    $repoName = $null

    function Write-RepoUsage {
        Write-Output 'Usage: repo [--https] [REPO]'
        Write-Output '       repo --pick'
        Write-Output '       repo --list'
        Write-Output '       repo --refresh-cache'
    }

    function Get-RepoCacheAge {
        if (-not [System.IO.File]::Exists($cacheFile)) { return [int]::MaxValue }
        $age = (Get-Date) - (Get-Item -LiteralPath $cacheFile).LastWriteTime
        return [int]$age.TotalSeconds
    }

    function Update-RepoCache {
        if (-not (Test-CommandExists gh)) { return $false }
        if (-not [System.IO.Directory]::Exists($cacheDir)) { New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null }
        $lock = "$cacheFile.lock"
        $tmp = "$cacheFile.tmp.$PID"
        $lockItem = New-Item -ItemType Directory -Path $lock -ErrorAction SilentlyContinue
        if (-not $lockItem) { return $true }
        try {
            $template = '{{range .}}{{.name}}{{"\t"}}{{.description}}{{"\n"}}{{end}}'
            $output = & gh repo list $owner --limit $repoLimit --json name,description --template $template 2>$null
            if (($LASTEXITCODE -eq 0) -and $output) {
                $output | Set-Content -Path $tmp -Encoding utf8
                Move-Item -Path $tmp -Destination $cacheFile -Force
                return $true
            }
            if ([System.IO.File]::Exists($tmp)) { Remove-Item -LiteralPath $tmp -Force }
            return $false
        } finally {
            Remove-Item -LiteralPath $lock -Force -ErrorAction SilentlyContinue
        }
    }

    function Get-RepoList {
        if (-not [System.IO.File]::Exists($cacheFile)) {
            [void](Update-RepoCache)
        } elseif ((Get-RepoCacheAge) -gt $cacheTtl) {
            [void](Update-RepoCache)
        }
        if ([System.IO.File]::Exists($cacheFile)) { Get-Content -LiteralPath $cacheFile }
    }

    function Select-RepoName {
        if (-not (Test-CommandExists fzf)) {
            Write-Error 'fzf is required for interactive repo selection'
            return $null
        }
        $repos = @(Get-RepoList)
        if (-not $repos -or ($repos.Count -eq 0)) {
            Write-Error 'No repositories found. Run repo --refresh-cache or check gh auth.'
            return $null
        }
        $height = if ($env:REPO_FZF_HEIGHT) { $env:REPO_FZF_HEIGHT } else { '80%' }
        $script = ". '$env:USERPROFILE\winconf\functions.ps1'; repo --refresh-cache; repo --list"
        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($script))
        $shell = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $reload = "`"$shell`" -NoProfile -EncodedCommand $encoded"
        $selection = $repos | fzf --height $height --layout reverse --border --prompt "$owner> " --delimiter "`t" --with-nth '1,2' --nth '1,2' --no-multi --header 'enter: clone  ctrl-r: refresh' --bind "ctrl-r:reload($reload)"
        if ($LASTEXITCODE -ne 0) { return $null }
        if (-not $selection) { return $null }
        return ($selection -split "`t")[0]
    }

    function Invoke-RepoClone {
        param([Parameter(Mandatory)][string]$InputRepo)

        if (($InputRepo -like 'http://*') -or ($InputRepo -like 'https://*') -or ($InputRepo -like 'git@*')) {
            $repoUrl = $InputRepo
            $repoDir = ($InputRepo.TrimEnd('/') -split '/')[-1] -replace '\.git$', ''
        } elseif ($InputRepo -like '*/*') {
            $repoDir = ($InputRepo -split '/')[-1]
            if ($useHttps) {
                $repoUrl = "https://github.com/$InputRepo.git"
            } else {
                $repoUrl = "git@github.com:$InputRepo.git"
            }
        } else {
            $repoDir = $InputRepo
            if ($useHttps) {
                $repoUrl = "https://github.com/$owner/$InputRepo.git"
            } else {
                $repoUrl = "git@github.com:$owner/$InputRepo.git"
            }
        }

        if (Test-Path -LiteralPath $repoDir) {
            Write-Error "REPO $repoDir already exists"
            return
        }

        & git clone $repoUrl
    }

    foreach ($arg in $Arguments) {
        if ($arg -eq '--https') { $useHttps = $true; continue }
        if (($arg -eq '--pick') -or ($arg -eq '--fzf')) { $pickRepo = $true; continue }
        if (($arg -eq '--list') -or ($arg -eq '--complete')) { Get-RepoList; return }
        if ($arg -eq '--refresh-cache') { if (Update-RepoCache) { $global:LASTEXITCODE = 0 } else { $global:LASTEXITCODE = 1 }; return }
        if (($arg -eq '-h') -or ($arg -eq '--help')) { Write-RepoUsage; return }
        if ($arg -like '--*') {
            Write-Error "Unrecognized argument: $arg"
            Write-RepoUsage
            return
        }
        if (-not $repoName) {
            $repoName = $arg
        } else {
            Write-Error "Unrecognized argument: $arg"
            Write-RepoUsage
            return
        }
    }

    if (-not $repoName) {
        if ($pickRepo -or ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected)) {
            $repoName = Select-RepoName
            if (-not $repoName) { return }
        } else {
            Write-RepoUsage
            return
        }
    }

    Invoke-RepoClone $repoName
}

function SetPermissions {
    param (
        [Parameter(Mandatory)]
        [string]$Dir
    )

    if (-not (Test-Path -LiteralPath $Dir)) {
        Write-Error "Path '$Dir' does not exist"
        return
    }

    $acl = Get-Acl -LiteralPath $Dir
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $accessRule = [System.Security.AccessControl.FileSystemAccessRule]::new($user, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $acl.SetAccessRule($accessRule)
    Set-Acl -LiteralPath $Dir -AclObject $acl
}

function Select-FromMenu {
    param(
        [Parameter(Mandatory)][array]$Items,
        [Parameter(Mandatory)][string]$Title,
        [string]$Property
    )
    if ($Items.Count -eq 0) { Write-Warning "Nothing to choose from."; return $null }
    Write-Host ""
    Write-Host $Title -ForegroundColor Cyan
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $label = if ($Property) { $Items[$i].$Property } else { $Items[$i] }
        Write-Host ("  [{0}] {1}" -f ($i + 1), $label)
    }
    Write-Host ""
    while ($true) {
        $raw = Read-Host "Select 1-$($Items.Count) (q to cancel)"
        if ($raw -match '^[qQ]') { return $null }
        if ($raw -match '^\d+$' -and [int]$raw -ge 1 -and [int]$raw -le $Items.Count) {
            return $Items[[int]$raw - 1]
        }
        Write-Host "Invalid choice." -ForegroundColor Yellow
    }
}

function Mount-Btrfs {
    param(
        [string]$Disk,
        [int]$Partition,
        [string]$Name = 'btrfs'
    )

    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')) {
        Write-Warning "wsl --mount requires an elevated PowerShell. Re-run as Administrator."
        return
    }

    if (-not $Disk) {
        $disks = Get-CimInstance Win32_DiskDrive |
            Select-Object DeviceID, Model,
                @{n='SizeGB'; e={[math]::Round($_.Size/1GB,1)}},
                @{n='Label';  e={"{0,-22} {1,8} GB  {2}" -f $_.Model, [math]::Round($_.Size/1GB,1), $_.DeviceID}}
        $pick = Select-FromMenu -Items $disks -Title "Select disk to mount in WSL:" -Property Label
        if (-not $pick) { Write-Host "Cancelled."; return }
        $Disk = $pick.DeviceID
    }

    if (-not $Partition) {
        if ($Disk -match 'PHYSICALDRIVE(\d+)') {
            $diskNum = [int]$Matches[1]
            $parts = Get-Partition -DiskNumber $diskNum -ErrorAction SilentlyContinue |
                Select-Object PartitionNumber, Type, DriveLetter,
                    @{n='SizeGB'; e={[math]::Round($_.Size/1GB,2)}},
                    @{n='Label';  e={"#{0}  {1,-18} {2,8} GB  {3}" -f $_.PartitionNumber, $_.Type, [math]::Round($_.Size/1GB,2), $(if ($_.DriveLetter) {"($($_.DriveLetter):)"} else {''})}}
            if (-not $parts) { Write-Warning "No partitions found on $Disk."; return }
            $pick = Select-FromMenu -Items $parts -Title "Select partition on $Disk :" -Property Label
            if (-not $pick) { Write-Host "Cancelled."; return }
            $Partition = $pick.PartitionNumber
            if ($pick.DriveLetter) {
                Write-Warning "Partition has drive letter $($pick.DriveLetter): in Windows. Remove it in Disk Management first, or mount will fail."
                $go = Read-Host "Continue anyway? (y/N)"
                if ($go -notmatch '^[yY]') { return }
            }
        } else {
            $Partition = [int](Read-Host "Partition number")
        }
    }

    Write-Host "Mounting $Disk partition $Partition as btrfs (name: $Name)..." -ForegroundColor Cyan
    wsl.exe --mount $Disk --partition $Partition --type btrfs --name $Name
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Mounted. Inside WSL: /mnt/wsl/$Name/" -ForegroundColor Green
    }
}

function Dismount-Btrfs {
    param([string]$Disk)

    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')) {
        Write-Warning "wsl --unmount requires an elevated PowerShell. Re-run as Administrator."
        return
    }

    if (-not $Disk) {
        $raw = wsl.exe --list --disk 2>$null
        $mounted = @($raw | Select-String -Pattern 'PHYSICALDRIVE\d+' | ForEach-Object { $_.Matches[0].Value } | Sort-Object -Unique | ForEach-Object { "\\.\$_" })
        if ($mounted.Count -eq 0) {
            Write-Host "No bare disks currently mounted in WSL." -ForegroundColor Yellow
            $all = Read-Host "Run 'wsl --unmount' (unmount ALL) anyway? (y/N)"
            if ($all -match '^[yY]') { wsl.exe --unmount }
            return
        }
        $items = $mounted + @('<unmount ALL>')
        $pick = Select-FromMenu -Items $items -Title "Select disk to unmount:"
        if (-not $pick) { Write-Host "Cancelled."; return }
        if ($pick -eq '<unmount ALL>') {
            Write-Host "Syncing and unmounting all..." -ForegroundColor Cyan
            wsl.exe -- sync
            wsl.exe --unmount
            return
        }
        $Disk = $pick
    }

    Write-Host "Syncing..." -ForegroundColor Cyan
    wsl.exe -- sync
    Write-Host "Unmounting $Disk..." -ForegroundColor Cyan
    wsl.exe --unmount $Disk
    if ($LASTEXITCODE -eq 0) { Write-Host "Unmounted." -ForegroundColor Green }
}

function CreateSymLink {
    param (
        [Parameter(Mandatory)]
        [string]$Src,

        [Parameter(Mandatory)]
        [string]$Target
    )

    $item = Get-Item -LiteralPath $Src -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -and ($item.Target -contains $Target)) { return $item }

    if ($item) {
        Remove-Item -LiteralPath $Src -Force -Recurse -Confirm:$false
    }

    $parent = Split-Path $Src -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    New-Item -ItemType SymbolicLink -Path $Src -Target $Target -Force
}
