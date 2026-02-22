@{
    RootModule        = 'helpers.psm1'
    ModuleVersion     = '2.0'
    GUID              = '284e0069-a6c6-4c8c-a8a1-3fa6b6ea46db'
    Author            = 'Andrius Solopovas'
    CompanyName       = 'Lyntouch Ltd'
    Copyright         = '(c) Andrius Solopovas. All rights reserved.'
    Description       = 'A collection of powershell utilities to help with daily tasks.'

    AliasesToExport   = @('hosts-edit')
    FunctionsToExport = @(
        # convertions.ps1
        'Convert-ExcelToCsv',
        'Convert-ToUnixEndings',
        'Format-String',
        # docker-compose.ps1
        'Dc',
        # files.ps1
        'Find-Replace',
        'Get-File',
        'New-File',
        'New-HardLink',
        'New-SymLink',
        'Test-IsSymLink',
        # firewall-blocker.ps1
        'ExecutablesStore',
        'LinuxDriveMounter',
        'ObjectStore',
        'Read-ObjectStore',
        'Write-ObjectStore',
        'firewallBlocker',
        # helpers.psm1
        'Get-RootName',
        'IIf',
        'Remove-CertByName',
        'Register-Cert',
        'Test-Sha',
        'UpdateModuleManifest',
        "Update-UserPath",
        # rm-pattern.ps1
        'Remove-ByPattern',
        # security.ps1
        'Add-DefenderExclusion',
        'Add-FirewallRule',
        'Clear-DefenderHistory',
        'DefenderMode',
        'Remove-FirewallRule',
        # system.ps1
        'Add-AdminShortcut',
        'Add-StartupItem',
        'Add-ToPath',
        'Clear-EventLogs',
        'Enable-Feature',
        'Find-LockingProcess',
        'RefreshUserPath',
        'Repair-Windows',
        'Restart-Explorer',
        'SortEnvPaths',
        'Start-AsAdmin',
        'Test-EnvPath',
        'Test-RegistryValue',
        'Test-ScheduledTask',
        'Update-UserPassword',
        'Write-ColorOutput',
        # tools.ps1
        'buildWebConfig',
        'clearShellContextMenu',
        'conf',
        'devHostMappings',
        'Edit-HostsWithVSCode',
        'gitRmPreviousCommits',
        'sshCopyID',
        'Show-EnvironmentPaths',
        'tail',
        # wsl.ps1
        'WslExport',
        'WslImport',
        'WslRemove',
        # devtools-custom-devices.ps1
        'Get-DevtoolDevices',
        'Set-DevtoolDevices'
    )
}
