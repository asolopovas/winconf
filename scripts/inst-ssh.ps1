param(
    [Parameter(Position = 0)]
    [ValidateSet("all", "generate", "convert", "permissions", "pageant", "deploy", "copy-id", "openssh")]
    [string]$Action = "all",

    [Parameter(Position = 1)]
    [string]$Target,

    [ValidateSet("ed25519", "rsa")]
    [string]$KeyType = "ed25519",

    [int]$Bits = 4096,

    [string]$KeyName,

    [string]$Identity,

    [switch]$Force,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$SshDir = "$env:USERPROFILE\.ssh"

function Write-Step([string]$Message) {
    Write-Host $Message -ForegroundColor Cyan
}

function Write-OK([string]$Message) {
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Skip([string]$Message) {
    Write-Host "  [SKIP] $Message" -ForegroundColor DarkGray
}

function Write-Fail([string]$Message) {
    Write-Host "  [FAIL] $Message" -ForegroundColor Red
}

function Assert-SshDirectory {
    if (-not (Test-Path $SshDir)) {
        New-Item -ItemType Directory -Path $SshDir -Force | Out-Null
        Write-OK "Created $SshDir"
    }
}

function Assert-WslPuttygen {
    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Write-Fail "WSL not found. Required for PPKv2 conversion."
        return $false
    }
    wsl bash -c "which puttygen" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Step "Installing putty-tools in WSL..."
        wsl bash -c "sudo apt install -y putty-tools" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "Failed to install putty-tools in WSL"
            return $false
        }
    }
    return $true
}

function Find-Pageant {
    $paths = @(
        "$env:LOCALAPPDATA\Programs\WinSCP\PuTTY\pageant.exe"
        "$env:ProgramFiles\PuTTY\pageant.exe"
        "${env:ProgramFiles(x86)}\PuTTY\pageant.exe"
    )
    $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
}

function Invoke-RemoteScript([string]$Script, [string[]]$Arguments) {
    $tmp = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tmp, $Script, [System.Text.UTF8Encoding]::new($false))
    $argString = if ($Arguments) { "-- " + (($Arguments | ForEach-Object { "`"$_`"" }) -join " ") } else { "" }
    cmd /c "type `"$tmp`" | ssh root bash -s $argString"
    $script:remoteExitCode = $LASTEXITCODE
    Remove-Item $tmp -Force
}

function Invoke-Generate {
    Assert-SshDirectory

    $name = if ($KeyName) { $KeyName } else { "id_$KeyType" }
    $keyPath = "$SshDir\$name"

    if ((Test-Path $keyPath) -and -not $Force) {
        Write-Skip "$keyPath already exists (use -Force to overwrite)"
        return
    }

    Write-Step "Generating $KeyType key: $name"

    $comment = "$env:USERNAME@$env:COMPUTERNAME"
    $args = @("-t", $KeyType, "-C", $comment, "-f", $keyPath, "-N", '""')
    if ($KeyType -eq "rsa") { $args += @("-b", $Bits) }

    & ssh-keygen @args 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "ssh-keygen failed"; return }

    Write-OK "$keyPath"
    Write-OK "$keyPath.pub"

    $fingerprint = ssh-keygen -l -f "$keyPath.pub" 2>&1
    Write-Host "  $fingerprint" -ForegroundColor DarkGray
}

function Invoke-Convert {
    Assert-SshDirectory
    if (-not (Assert-WslPuttygen)) { return }

    Write-Step "Converting private keys to PPKv2 format"

    $privateKeys = Get-ChildItem "$SshDir\id_*" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -notin ".pub", ".ppk" }

    if (-not $privateKeys) {
        Write-Fail "No private keys found in $SshDir"
        return
    }

    foreach ($key in $privateKeys) {
        $ppkPath = [System.IO.Path]::ChangeExtension($key.FullName, ".ppk")
        if ((Test-Path $ppkPath) -and -not $Force) {
            Write-Skip "$($key.Name) -> PPK already exists"
            continue
        }

        $winKey = $key.FullName -replace '\\', '/'
        $winPpk = $ppkPath -replace '\\', '/'
        $wslKeyPath = (wsl bash -c "wslpath -u '$winKey'").Trim()
        $wslPpkPath = (wsl bash -c "wslpath -u '$winPpk'").Trim()
        wsl bash -c "puttygen '$wslKeyPath' -O private --ppk-param version=2 -o '$wslPpkPath'" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-OK "$($key.Name) -> $([System.IO.Path]::GetFileName($ppkPath))"
        }
        else {
            Write-Fail "Could not convert $($key.Name)"
        }
    }
}

function Invoke-Permissions {
    if (-not (Test-Path $SshDir)) {
        Write-Fail "$SshDir does not exist"
        return
    }

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if (-not $isAdmin) {
        Write-Step "Relaunching as Administrator for permission fix..."
        Start-Process pwsh "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" permissions" -Verb RunAs
        return
    }

    Write-Step "Fixing permissions on $SshDir"
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    icacls $SshDir /setowner $user /T /C /Q 2>&1 | Out-Null
    icacls $SshDir /inheritance:r /Q 2>&1 | Out-Null
    icacls $SshDir /grant "${user}:F" /Q 2>&1 | Out-Null
    icacls $SshDir /remove:g "Authenticated Users" /Q 2>&1 | Out-Null
    icacls $SshDir /remove:g "Users" /Q 2>&1 | Out-Null

    Get-ChildItem $SshDir -Recurse -File | ForEach-Object {
        icacls $_.FullName /inheritance:r /Q 2>&1 | Out-Null
        icacls $_.FullName /grant "${user}:F" /Q 2>&1 | Out-Null
        icacls $_.FullName /remove:g "Authenticated Users" /Q 2>&1 | Out-Null
        icacls $_.FullName /remove:g "Users" /Q 2>&1 | Out-Null
    }

    Write-OK "Permissions fixed for $SshDir"
}

function Invoke-Pageant {
    $pageantExe = Find-Pageant
    if (-not $pageantExe) {
        Write-Fail "Pageant not found"
        return
    }

    $ppkFiles = Get-ChildItem "$SshDir\*.ppk" -ErrorAction SilentlyContinue
    if (-not $ppkFiles) {
        Write-Fail "No PPK keys found in $SshDir. Run: inst-ssh.ps1 convert"
        return
    }

    Write-Step "Configuring Pageant scheduled task"

    $ppkArgs = ($ppkFiles.FullName | ForEach-Object { "`"$_`"" }) -join " "
    $machineName = (Get-CimInstance Win32_ComputerSystem).Name
    $taskName = "Pageant-$env:UserName"

    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    $taskAction = New-ScheduledTaskAction -Execute $pageantExe -Argument $ppkArgs
    $taskTrigger = New-ScheduledTaskTrigger -AtLogon -User "$machineName\$env:UserName"
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId "$machineName\$env:UserName" -LogonType Interactive -RunLevel Limited
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    $task = New-ScheduledTask -Action $taskAction -Principal $taskPrincipal -Trigger $taskTrigger -Settings $taskSettings
    Register-ScheduledTask -TaskName $taskName -InputObject $task | Out-Null

    Stop-Process -Name pageant -Force -ErrorAction SilentlyContinue
    Start-Sleep 1
    Start-ScheduledTask -TaskName $taskName

    Write-OK "Pageant task '$taskName' registered and started"
    Write-Host "  Keys loaded: $($ppkFiles.Count)" -ForegroundColor DarkGray
}

function Invoke-OpenSSH {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if (-not $isAdmin) {
        Write-Step "Relaunching as Administrator for OpenSSH setup..."
        Start-Process pwsh "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" openssh" -Verb RunAs
        return
    }

    Write-Step "Installing OpenSSH capabilities"
    Add-WindowsCapability -Online -Name "OpenSSH.Client~~~~0.0.1.0" -ErrorAction SilentlyContinue
    Add-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0" -ErrorAction SilentlyContinue

    Write-Step "Configuring sshd service"
    Start-Service sshd -ErrorAction SilentlyContinue
    Set-Service -Name sshd -StartupType Automatic

    Write-Step "Setting default shell to pwsh"
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell `
        -Value "C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force | Out-Null

    $ruleName = "OpenSSH-Server-In-TCP"
    if (-not (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name $ruleName -DisplayName "OpenSSH Server (sshd)" `
            -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
        Write-OK "Firewall rule created"
    }
    else {
        Write-Skip "Firewall rule already exists"
    }

    Write-OK "OpenSSH configured"
}

function Invoke-CopyId {
    if (-not $Target) {
        Write-Fail "Usage: inst-ssh.ps1 copy-id <host> [-Identity <key.pub>]"
        return
    }

    $pubKey = if ($Identity) { $Identity } else { "$SshDir\id_ed25519.pub" }

    if (-not (Test-Path $pubKey)) {
        $pubKey = "$SshDir\id_rsa.pub"
    }

    if (-not (Test-Path $pubKey)) {
        Write-Fail "No public key found. Run: inst-ssh.ps1 generate"
        return
    }

    Write-Step "Copying $([System.IO.Path]::GetFileName($pubKey)) to $Target"

    $keyContent = (Get-Content $pubKey -Raw).Trim()
    $remoteCmd = "umask 077; test -d .ssh || mkdir .ssh; echo '$keyContent' >> .ssh/authorized_keys; sort -u -o .ssh/authorized_keys .ssh/authorized_keys"
    ssh $Target $remoteCmd

    if ($LASTEXITCODE -eq 0) { Write-OK "Key installed on $Target" }
    else { Write-Fail "Failed to copy key to $Target" }
}

function Invoke-Deploy {
    $pubKey = if ($Identity) { $Identity } else { "$SshDir\id_ed25519.pub" }

    if (-not (Test-Path $pubKey)) {
        $pubKey = "$SshDir\id_rsa.pub"
    }

    if (-not (Test-Path $pubKey)) {
        Write-Fail "No public key found. Run: inst-ssh.ps1 generate"
        return
    }

    $keyContent = (Get-Content $pubKey -Raw).Trim()

    if ($keyContent -notmatch '^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp\d+) ') {
        Write-Fail "Invalid SSH public key format"
        return
    }

    $forceVal = if ($Force) { "1" } else { "0" }
    $dryRunVal = if ($DryRun) { "1" } else { "0" }

    if ($DryRun) {
        Write-Step "Dry-run: Deploying $([System.IO.Path]::GetFileName($pubKey)) to Plesk vhosts"
    }
    else {
        Write-Step "Deploying $([System.IO.Path]::GetFileName($pubKey)) to Plesk vhosts"
    }

    $keyB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($keyContent))

    $remoteScript = @'
force="$1"
dry_run="$2"
public_key="$(echo "$3" | base64 -d)"

plesk_users="$(plesk db -N -B -e "
    SELECT d.name, s.login, s.home FROM domains d
    JOIN hosting h ON d.id = h.dom_id
    JOIN sys_users s ON h.sys_user_id = s.id
    WHERE d.htype = 'vrt_hst'")"

user_count=0; updated_count=0; skipped_count=0
while IFS=$'\t' read -r domain plesk_user home_dir; do
    [ -z "$domain" ] || [ -z "$plesk_user" ] || [ -z "$home_dir" ] && continue
    id "$plesk_user" &>/dev/null || continue
    [ -d "$home_dir" ] || continue
    user_count=$((user_count + 1))
    ssh_dir="$home_dir/.ssh"
    authorized_keys="$ssh_dir/authorized_keys"
    if [ "$dry_run" = "1" ]; then
        if [ "$force" = "1" ]; then
            echo "  [DRY-RUN] Would overwrite: $plesk_user ($domain)"
        elif [ -f "$authorized_keys" ] && grep -qxF "$public_key" "$authorized_keys"; then
            echo "  [DRY-RUN] Already present: $plesk_user ($domain)"
        else
            echo "  [DRY-RUN] Would append: $plesk_user ($domain)"
        fi
        continue
    fi
    if [ ! -d "$ssh_dir" ]; then
        mkdir -p "$ssh_dir"
        chown "$plesk_user":"$plesk_user" "$ssh_dir"
        chmod 700 "$ssh_dir"
    fi
    if [ "$force" = "1" ]; then
        echo "$public_key" > "$authorized_keys"
        echo "  [OK] Overwritten: $plesk_user ($domain)"
        updated_count=$((updated_count + 1))
    elif [ -f "$authorized_keys" ] && grep -qxF "$public_key" "$authorized_keys"; then
        echo "  [SKIP] $plesk_user ($domain)"
        skipped_count=$((skipped_count + 1))
    else
        echo "$public_key" >> "$authorized_keys"
        echo "  [OK] $plesk_user ($domain)"
        updated_count=$((updated_count + 1))
    fi
    chmod 600 "$authorized_keys"
    chown "$plesk_user":psacln "$authorized_keys"
done <<< "$plesk_users"
echo ""
echo "  Processed $user_count user(s): $updated_count updated, $skipped_count skipped"
'@

    Invoke-RemoteScript $remoteScript @($forceVal, $dryRunVal, $keyB64)
    if ($script:remoteExitCode -ne 0) { Write-Fail "Remote deployment failed" }
    elseif (-not $DryRun) { Write-OK "Deployed to all Plesk vhosts" }
}

function Invoke-All {
    Write-Host ""
    Write-Host "  inst-ssh: Full SSH Configuration" -ForegroundColor White
    Write-Host "  =================================" -ForegroundColor DarkGray
    Write-Host ""

    Invoke-Generate
    Invoke-Convert
    Invoke-Permissions
    Invoke-Pageant
    Invoke-Deploy

    Write-Host ""
    Write-OK "SSH setup complete"
}

function Show-Help {
    Write-Host ""
    Write-Host "  inst-ssh.ps1 - Consolidated SSH key management" -ForegroundColor White
    Write-Host ""
    Write-Host "  Usage: inst-ssh.ps1 <action> [options]" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Actions:" -ForegroundColor Yellow
    Write-Host "    all          Run full setup (generate, convert, permissions, pageant, deploy)"
    Write-Host "    generate     Generate SSH key pair (Ed25519 by default)"
    Write-Host "    convert      Convert private keys to PPKv2 format for Directory Opus"
    Write-Host "    permissions  Fix ACLs on ~/.ssh directory (requires admin)"
    Write-Host "    pageant      Configure Pageant scheduled task with PPK keys"
    Write-Host "    deploy       Deploy public key to all Plesk vhosts via root"
    Write-Host "    copy-id      Copy public key to a single remote host"
    Write-Host "    openssh      Install and configure Windows OpenSSH server"
    Write-Host ""
    Write-Host "  Options:" -ForegroundColor Yellow
    Write-Host "    -KeyType     ed25519 (default) or rsa"
    Write-Host "    -Bits        RSA key size (default 4096)"
    Write-Host "    -KeyName     Custom key filename (default: id_<type>)"
    Write-Host "    -Identity    Path to public key file for deploy/copy-id"
    Write-Host "    -Force       Overwrite existing keys/PPKs"
    Write-Host "    -DryRun      Preview deploy without changes"
    Write-Host ""
    Write-Host "  Examples:" -ForegroundColor Yellow
    Write-Host "    inst-ssh.ps1                             # Full setup with Ed25519"
    Write-Host "    inst-ssh.ps1 generate                    # Generate Ed25519 key"
    Write-Host "    inst-ssh.ps1 generate -KeyType rsa       # Generate RSA key"
    Write-Host "    inst-ssh.ps1 convert                     # Convert all keys to PPKv2"
    Write-Host "    inst-ssh.ps1 convert -Force              # Re-convert all keys"
    Write-Host "    inst-ssh.ps1 deploy -DryRun              # Preview Plesk deployment"
    Write-Host "    inst-ssh.ps1 deploy -Force               # Overwrite all authorized_keys"
    Write-Host "    inst-ssh.ps1 copy-id root                # Copy key to 'root' host"
    Write-Host "    inst-ssh.ps1 copy-id threeoakwood        # Copy key to specific host"
    Write-Host ""
}

switch ($Action) {
    "all"         { Invoke-All }
    "generate"    { Invoke-Generate }
    "convert"     { Invoke-Convert }
    "permissions" { Invoke-Permissions }
    "pageant"     { Invoke-Pageant }
    "openssh"     { Invoke-OpenSSH }
    "copy-id"     { Invoke-CopyId }
    "deploy"      { Invoke-Deploy }
    default       { Show-Help }
}
