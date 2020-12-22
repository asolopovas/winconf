function Phpmyadmin-Download() {
  $cache = "$dev_root\.cache"
  $filename = "phpMyAdmin-$ver-english.zip"
  $url = "https://files.phpmyadmin.net/phpMyAdmin/$ver/$filename"

  if ( !(Test-Path "$cache\$filename") ) {
    File-Get $url $cache
  }
  7z x "$cache\$filename" -o"$dev_root"
  Rename-Item "$dev_root\phpMyAdmin-$ver-english" "$dev_root\$hostname"
  Copy-Item "$dev_configs\phpmyadmin.php" $dev_root\$hostname\config.inc.php
}

function Phpmyadmin-Install($ver = "4.9.1") {
  $hostname = "phpmyadmin.test"

  if (Test-Path "$dev_root\$hostname") {
    $result = Prompt-User "$dev_root\$hostname already exist." "Do you want to delete it?"

    if ( $result ) {
      Remove-Item -Recurse "$dev_root\$hostname"
      Phpmyadmin-Download
    }
  } else {
    Phpmyadmin-Download
  }

  IIS-Host-Add $hostname
  Certificate-Host-Generate $hostname
  IIS-HostBinding $hostname

}

Export-ModuleMember -Alias * -Function *
