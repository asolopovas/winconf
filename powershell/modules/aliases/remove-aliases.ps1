$removeAliases = @(
    'gc'
    'gp'
    'gl'
)

foreach ($alias in $removeAliases) {
    if (Get-Alias -Name $alias -ErrorAction SilentlyContinue) {
        Remove-Item -Force Alias:$alias
    }
}
