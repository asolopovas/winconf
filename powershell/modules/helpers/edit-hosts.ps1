function Edit-HostsWithVSCode {
    [CmdletBinding()]
    param ()

    $hostsFile = "C:\Windows\System32\drivers\etc\hosts"
    $codeExe = "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe"

    if (-not (Test-Path $codeExe)) {
        Write-Error "VS Code executable not found at $codeExe"
        return
    }

    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "Restarting with administrative privileges..."

        $codeToRun = @"
Stop-Process -Name Code -Force -ErrorAction SilentlyContinue
`$hostsFile = '$hostsFile'
`$codeExe = '$codeExe'
Start-Process "`$codeExe" -ArgumentList '--new-window', "`"`$hostsFile`"" -Verb RunAs
"@

        Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile", "-Command", $codeToRun
        return
    }

    # Kill existing VS Code processes to ensure elevation works
    Stop-Process -Name Code -Force -ErrorAction SilentlyContinue

    Start-Process $codeExe -ArgumentList "--new-window", "--wait", "`"$hostsFile`"" -Verb RunAs
    Write-Host "VS Code opened with admin rights. Edit the file, then close the window."
}



Set-Alias -Name ehosts -Value Edit-HostsWithVSCode
