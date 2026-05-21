function Test-CommandExists {
    param (
        [Parameter(Mandatory)]
        [string]$Command
    )

    [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function SetPermissions {
    param (
        [Parameter(Mandatory)]
        [string]$Dir
    )

    if (-not (Test-Path $Dir)) {
        Write-Error "Path '$Dir' does not exist"
        return
    }

    $acl = Get-Acl $Dir
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $env:UserName, "FullControl", "Allow"
    )
    $acl.SetAccessRule($accessRule)
    Set-Acl $Dir $acl
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

    Remove-Item -Force -Recurse -Confirm:$false $Src -ErrorAction SilentlyContinue
    New-Item -ItemType SymbolicLink -Path $Src -Target $Target -Force
}
