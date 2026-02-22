@{
    RootModule        = 'helpers.psm1'
    ModuleVersion     = '2.0'
    GUID              = '284e0069-a6c6-4c8c-a8a1-3fa6b6ea46db'
    Author            = 'Andrius Solopovas'
    CompanyName       = 'Lyntouch Ltd'
    Copyright         = '(c) Andrius Solopovas. All rights reserved.'
    Description       = 'A collection of powershell utilities to help with daily tasks.'

    AliasesToExport   = @('hosts-edit', 'dc')
    FunctionsToExport = @(
        'Convert-ExcelToCsv',
        'Convert-ExcelToCsvDir',
        'Convert-ToUnixEndings',
        'Format-String',
        'Dc',
        'Find-Replace',
        'Get-File',
        'New-File',
        'New-HardLink',
        'New-SymLink',
        'Test-IsSymLink',
        'ExecutablesStore',
        'ObjectStore',
        'firewallBlocker',
        'Get-RootName',
        'IIf',
        'LinuxDriveMounter',
        'Remove-CertByName',
        'Register-Cert',
        'Test-Sha',
        'UpdateModuleManifest',
        'Update-UserPath',
        'Remove-ByPattern',
        'Add-DefenderExclusion',
        'Add-FirewallRule',
        'Clear-DefenderHistory',
        'DefenderMode',
        'Remove-FirewallRule',
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
        'clearShellContextMenu',
        'conf',
        'Edit-HostsWithVSCode',
        'gitRmPreviousCommits',
        'sshCopyID',
        'Show-EnvironmentPaths',
        'tail',
        'WslExport',
        'WslImport',
        'WslRemove',
        'Get-DevtoolDevices',
        'Set-DevtoolDevices'
    )
}
