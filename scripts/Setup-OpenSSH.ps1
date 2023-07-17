. $env:userprofile\winconf\functions.ps1

Add-Capability "OpenSSH.Client~~~~0.0.1.0"
Add-Capability "OpenSSH.Server~~~~0.0.1.0"

# Function to start the sshd service and set its startup type
Function ConfigureSSHDService {
    # Start the sshd service
    Start-Service sshd

    # Set sshd service to start up automatically
    Set-Service -Name sshd -StartupType 'Automatic'
}

ConfigureSSHDService

# Set the default shell for OpenSSH
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force

# Function to configure the Firewall rule for OpenSSH
Function ConfigureFirewallRule {
    $firewallRuleName = "OpenSSH-Server-In-TCP"
    $firewallRule = Get-NetFirewallRule -Name $firewallRuleName -ErrorAction SilentlyContinue
    if (!$firewallRule) {
        Write-Output "Firewall Rule '$firewallRuleName' does not exist, creating it..."
        New-NetFirewallRule -Name $firewallRuleName -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    } else {
        Write-Output "Firewall rule '$firewallRuleName' has been created and exists."
    }
}

ConfigureFirewallRule
