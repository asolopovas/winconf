@{
    RootModule        = 'helpers.psm1'
    ModuleVersion     = '2.0'
    GUID              = '284e0069-a6c6-4c8c-a8a1-3fa6b6ea46db'
    Author            = 'Andrius Solopovas'
    CompanyName       = 'Lyntouch Ltd'
    Copyright         = '(c) Andrius Solopovas. All rights reserved.'
    Description       = 'A collection of powershell utilities to help with daily tasks.'

    FunctionsToExport = @(
        # convertions.ps1
        'Convert-ToUnixEndings',
        'Convert-ExcelToCsv',
        'Format-String',
        # docker-compose.ps1
        'Dc',
        # files.ps1
        'New-SymLink',
        'New-HardLink',
        'New-File',
        'Test-IsSymLink',
        'Find-Replace',
        'Get-File',
        # firewall-blocker.ps1
        'ObjectStore',
        'Read-ObjectStore',
        'Write-ObjectStore',
        'ExecutablesStore',
        'firewallBlocker',
        # helpers.psm1
        'Get-RootName',
        'IIf',
        'UpdateModuleManifest',
        # rm-pattern.ps1
        'Remove-ByPattern',
        # security.ps1
        'Add-FirewallRule',
        'Remove-FirewallRule',
        'Add-DefenderExclusion',
        'Clear-DefenderHistory',
        'Disable-AntivirusMode',
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
        'Start-AsAdmin',
        'SortEnvPaths',
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
        'gitRmPreviousCommits',
        'sshCopyID',
        'tail',
        # wsl.ps1
        'WslRemove',
        'WslImport',
        'WslExport'
    )
}
