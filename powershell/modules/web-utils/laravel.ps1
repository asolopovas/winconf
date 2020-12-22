function Laravel-New([string]$name) {
  if (!$name) { return "Please provide `$name parameter" }
  Push-Location $dev_root
  laravel new $name
  Push-Location "$pwd\$name"
  Site-New -laravel
  Pop-Location
}

Export-ModuleMember -Alias * -Function *
