$removeAliases = @(
    'gc'
    'gp'
    'gl'
)

foreach ($alias in $removeAliases) {
    Remove-Item -Force Alias:$alias
}
