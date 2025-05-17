function Edit-HostsWithVSCode {
    [CmdletBinding()]
    param ()

    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "Restarting function with administrative privileges..."
        $script = @"
function tempEditHosts {
    Remove-Item Function:\tempEditHosts -Force
    ${function:Edit-HostsWithVSCode}
    Edit-HostsWithVSCode
}
tempEditHosts
"@
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `$scriptBlock = [ScriptBlock]::Create(`"$script`"); Invoke-Command -ScriptBlock `$scriptBlock" -Verb RunAs
        return
    }

    $hostsFile = "C:\Windows\System32\drivers\etc\hosts"

    if (-not (Get-Command "code" -ErrorAction SilentlyContinue)) {
        Write-Error "VS Code (code) not found in PATH. Please ensure it is installed and added to your system PATH."
        return
    }

    code $hostsFile

    Write-Host "Hosts file opened in VS Code. Press Enter when you're done editing..."
    Read-Host

    if ((Get-Item $hostsFile).LastWriteTime -gt (Get-Date).AddMinutes(-5)) {
        Write-Host "Hosts file was recently modified."
    }
    else {
        Write-Warning "It doesn't look like the file was recently saved. Ensure you saved it in VS Code."
    }
}

Set-Alias -Name ehosts -Value Edit-HostsWithVSCode

