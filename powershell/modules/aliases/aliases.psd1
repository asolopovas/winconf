@{

    RootModule        = 'aliases.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '52b86611-6a12-4960-944c-679643acab2c'
    Author            = 'Andrius Solopovas'
    CompanyName       = 'Lyntouch Ltd'
    Copyright         = '(c) Lytnouch Ltd. All rights reserved'
    Description       = 'Global Aliases for powershell'
    FunctionsToExport = @(
        'ga',
        'gb',
        'gc',
        'gs',
        'gd',
        'gk',
        'gg',
        'gt',
        'gp',
        'gpo',
        'gpf',
        'gl',
        'gsclone',
        'ghclone',
        'gundo',
        'nah',
        'bfg',
        'gw',
        'ci',
        'cr',
        'pi',
        'pu',
        'pr',
        'lsChoco',
        'lsModules'
    )
    AliasesToExport   = @(
        'which',
        'pt',
        'grep',
        'dk',
        'l',
        'pbpaste',
        'ppaste',
        'pbcopy',
        'pcopy'
    )

}
