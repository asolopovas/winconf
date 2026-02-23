param(
    [string]$VmDir,
    [switch]$All
)

$defaultVmDir = Join-Path $env:USERPROFILE "Documents\Virtual Machines"
$searchDir = if ($VmDir) { $VmDir } else { $defaultVmDir }

if (-not (Test-Path $searchDir)) {
    Write-Host "  VM directory not found: $searchDir" -ForegroundColor Red
    return
}

$vmxFiles = Get-ChildItem -Path $searchDir -Filter "*.vmx" -Recurse -ErrorAction SilentlyContinue |
    Where-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        $content -match 'guestOS\s*=\s*"darwin'
    }

if (-not $vmxFiles -or $vmxFiles.Count -eq 0) {
    Write-Host "  No macOS VMs found in $searchDir" -ForegroundColor Yellow
    return
}

Write-Host ""
Write-Host "  Found $($vmxFiles.Count) macOS VM(s):" -ForegroundColor Cyan
Write-Host ""

for ($i = 0; $i -lt $vmxFiles.Count; $i++) {
    $vmx = $vmxFiles[$i]
    $content = Get-Content $vmx.FullName -ErrorAction SilentlyContinue
    $name = ($content | Where-Object { $_ -match '^displayName\s*=' }) -replace 'displayName\s*=\s*"(.*)"', '$1'
    $guest = ($content | Where-Object { $_ -match '^guestOS\s*=' }) -replace 'guestOS\s*=\s*"(.*)"', '$1'
    if (-not $name) { $name = $vmx.BaseName }
    Write-Host "  [$($i + 1)] $name ($guest)" -ForegroundColor White
    Write-Host "      $($vmx.FullName)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  [A] All VMs" -ForegroundColor White
Write-Host "  [Q] Quit" -ForegroundColor White
Write-Host ""

$selected = @()

if ($All) {
    $selected = $vmxFiles
} else {
    $choice = Read-Host "  Select VMs (comma-separated numbers, A for all, Q to quit)"
    $choice = $choice.Trim()

    if ($choice -eq 'Q' -or $choice -eq 'q') { return }

    if ($choice -eq 'A' -or $choice -eq 'a') {
        $selected = $vmxFiles
    } else {
        $indices = $choice -split ',' | ForEach-Object {
            $num = $_.Trim() -as [int]
            if ($num -and $num -ge 1 -and $num -le $vmxFiles.Count) { $num - 1 }
        }
        $selected = $indices | ForEach-Object { $vmxFiles[$_] }
    }
}

if (-not $selected -or @($selected).Count -eq 0) {
    Write-Host "  No VMs selected" -ForegroundColor Yellow
    return
}

$requiredSettings = [ordered]@{
    "smc.version"                    = '"0"'
    "hw.model"                       = '"iMacPro1,1"'
    "serialNumber.reflectHost"       = '"FALSE"'
    "SMBIOS.use12CharSerialNumber"   = '"TRUE"'
    "cpuid.0.eax"                    = '"0000:0000:0000:0000:0000:0000:0000:1011"'
    "cpuid.0.ebx"                    = '"0111:0101:0110:1110:0110:0101:0100:0111"'
    "cpuid.0.ecx"                    = '"0110:1100:0110:0101:0111:0100:0110:1110"'
    "cpuid.0.edx"                    = '"0100:1001:0110:0101:0110:1110:0110:1001"'
    "cpuid.1.eax"                    = '"0000:0000:0000:0001:0000:0110:0111:0001"'
    "cpuid.1.ebx"                    = '"0000:0010:0000:0001:0000:1000:0000:0000"'
    "cpuid.1.ecx"                    = '"1000:0010:1001:1000:0010:0010:0000:0011"'
    "cpuid.1.edx"                    = '"0000:0111:1000:1011:1111:1011:1111:1111"'
}

$requiredEntries = [ordered]@{
    "smc.present"                    = '"TRUE"'
    "firmware"                       = '"efi"'
    "board-id.reflectHost"           = '"TRUE"'
    "ich7m.present"                  = '"TRUE"'
}

$bootFixSettings = @{
    "sata0:1.deviceType"  = '"cdrom-raw"'
    "sata0:1.fileName"    = '"auto detect"'
    "sata0:1.autodetect"  = '"TRUE"'
    "bios.bootOrder"      = '"hdd"'
}

function Update-VmxFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $lines = Get-Content $Path
    $content = $lines -join "`n"
    $modified = $false
    $changes = @()

    foreach ($key in $requiredEntries.Keys) {
        $pattern = "(?m)^$([regex]::Escape($key))\s*="
        if ($content -notmatch $pattern) {
            $lines += "$key = $($requiredEntries[$key])"
            $changes += "added $key"
            $modified = $true
        }
    }

    foreach ($key in $requiredSettings.Keys) {
        $pattern = "(?m)^$([regex]::Escape($key))\s*="
        $expectedLine = "$key = $($requiredSettings[$key])"
        if ($content -match $pattern) {
            $lines = $lines | ForEach-Object {
                if ($_ -match "^$([regex]::Escape($key))\s*=") {
                    if ($_ -ne $expectedLine) {
                        $changes += "updated $key"
                        $modified = $true
                        $expectedLine
                    } else { $_ }
                } else { $_ }
            }
        } else {
            $lines += $expectedLine
            $changes += "added $key"
            $modified = $true
        }
    }

    $hasCdromImage = $lines | Where-Object { $_ -match '^sata0:1\.deviceType\s*=\s*"cdrom-image"' }
    if ($hasCdromImage) {
        foreach ($key in $bootFixSettings.Keys) {
            $expectedLine = "$key = $($bootFixSettings[$key])"
            $lines = $lines | ForEach-Object {
                if ($_ -match "^$([regex]::Escape($key))\s*=") {
                    if ($_ -ne $expectedLine) {
                        $changes += "updated $key"
                        $modified = $true
                        $expectedLine
                    } else { $_ }
                } else { $_ }
            }
            $hasKey = $lines | Where-Object { $_ -match "^$([regex]::Escape($key))\s*=" }
            if (-not $hasKey) {
                $lines += $expectedLine
                $changes += "added $key"
                $modified = $true
            }
        }
    }

    if ($modified) {
        Copy-Item -Path $Path -Destination "$Path.bak" -Force
        $lines | Set-Content -Path $Path -Encoding UTF8
    }

    return @{ Modified = $modified; Changes = $changes }
}

Write-Host ""

foreach ($vmx in $selected) {
    $content = Get-Content $vmx.FullName -ErrorAction SilentlyContinue
    $name = ($content | Where-Object { $_ -match '^displayName\s*=' }) -replace 'displayName\s*=\s*"(.*)"', '$1'
    if (-not $name) { $name = $vmx.BaseName }

    $lockFile = Get-ChildItem -Path $vmx.DirectoryName -Filter "*.vmx.lck" -Directory -ErrorAction SilentlyContinue
    if ($lockFile) {
        Write-Host "  [$name] VM appears to be running - skipping" -ForegroundColor Red
        Write-Host "    Power off the VM first, then re-run this script" -ForegroundColor DarkGray
        continue
    }

    Write-Host "  [$name] Applying macOS VM fixes..." -ForegroundColor Cyan

    $result = Update-VmxFile -Path $vmx.FullName

    if ($result.Modified) {
        Write-Host "  [$name] Backup saved: $($vmx.Name).bak" -ForegroundColor DarkGray
        foreach ($change in $result.Changes) {
            Write-Host "    $change" -ForegroundColor Green
        }
    } else {
        Write-Host "  [$name] All settings already configured" -ForegroundColor DarkGray
    }

    Write-Host ""
}

Write-Host "  Done" -ForegroundColor Green
