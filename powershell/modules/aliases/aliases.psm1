. $PSScriptRoot/git-aliases.ps1
. $PSScriptRoot/package-managers.ps1

function lsChoco { choco list --local-only }

function lsModules {
    [CmdletBinding()]
    param()
  (Get-Module -ListAvailable | Select-Object -ExpandProperty Name)
}

New-Alias -Name which   -Scope Global -Value Get-Command
New-Alias -Name l       -Scope Global -Value Get-ChildItem
New-Alias -Name grep    -Scope Global -Value Select-String
New-Alias -Name dk      -Scope Global -Value docker.exe
New-Alias -Name pbpaste -Scope Global -Value Get-Clipboard
New-Alias -Name ppaste  -Scope Global -Value Get-Clipboard
New-Alias -Name pbcopy  -Scope Global -Value Set-Clipboard
New-Alias -Name pcopy   -Scope Global -Value Set-Clipboard

New-Alias -Name "pt" -Value poetry.exe

function rs {
    $cwrsyncBin = "$env:USERPROFILE\scoop\apps\cwrsync\current\bin"
    $sshExe = "$cwrsyncBin\ssh.exe"
    $rsyncExe = "$cwrsyncBin\rsync.exe"

    # Convert arguments: Windows paths -> /cygdrive/ paths, resolve SSH config hosts
    $converted = @()
    $sshArgs = @()

    foreach ($arg in $args) {
        # Parse remote destination like host:path or user@host:path
        if ($arg -match '^(?:([^@]+)@)?([^:]+):(.+)$') {
            $user = $Matches[1]
            $hostAlias = $Matches[2]
            $remotePath = $Matches[3]

            # Resolve SSH config: get HostName, User, Port
            $sshConfig = ssh -G $hostAlias 2>$null
            if ($sshConfig) {
                $hostname = ($sshConfig | Select-String '^hostname\s+(.+)').Matches[0].Groups[1].Value
                $port = ($sshConfig | Select-String '^port\s+(.+)').Matches[0].Groups[1].Value
                $cfgUser = ($sshConfig | Select-String '^user\s+(.+)').Matches[0].Groups[1].Value
                $identFiles = ($sshConfig | Select-String '^identityfile\s+(.+)') | ForEach-Object { $_.Matches[0].Groups[1].Value }

                if (-not $user) { $user = $cfgUser }
                if ($port -and $port -ne '22') { $sshArgs += @('-p', $port) }

                # Find first identity file that exists
                foreach ($ident in $identFiles) {
                    $resolved = $ident -replace '^~', $env:USERPROFILE
                    if (Test-Path $resolved) {
                        $cygIdent = $resolved -replace '\\', '/' -replace '^([A-Za-z]):', '/cygdrive/$1'
                        $sshArgs += @('-i', $cygIdent)
                        break
                    }
                }

                $converted += "${user}@${hostname}:${remotePath}"
            } else {
                $converted += $arg
            }
        }
        # Convert Windows local paths to cygdrive
        elseif ($arg -match '^([A-Za-z]):[/\\]') {
            $converted += ($arg -replace '\\', '/' -replace '^([A-Za-z]):', '/cygdrive/$1')
        }
        # Convert relative paths to absolute cygdrive paths
        elseif (($arg -match '^\.') -and (Test-Path $arg -ErrorAction SilentlyContinue)) {
            $abs = (Resolve-Path $arg).Path
            $converted += ($abs -replace '\\', '/' -replace '^([A-Za-z]):', '/cygdrive/$1')
        }
        else {
            $converted += $arg
        }
    }

    $sshCmd = "`"$sshExe`" -o StrictHostKeyChecking=accept-new $($sshArgs -join ' ')"
    & $rsyncExe -azr --info=progress2 -e $sshCmd @converted
}

