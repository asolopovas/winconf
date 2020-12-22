function Wordpress-DbName($hostname) {
  $rootName = Site-Root-Name $hostname
  $snakeCaseName = String-To snakeCase $rootName
  $dbName = $snakeCaseName + "_wp"
  return $dbName
}

function Wordpress-DbFileUpdate($filePath, $oldHostname, $newHostname) {
  $rootName = Site-Root-Name $newHostname
  $rootPath = $dev_root.replace('\', '/')
  File-ContentsReplace $filePath $oldHostname $newHostname
  File-ContentsReplace $filePath "/home/$rootName/public_html" "$rootPath/$newHostname"
}

function Wordpress-Download($hostname) {
$filename = "wordpress-$wordpress_ver.zip"
$url = "https://wordpress.org/$filename"
  if (!(Test-Path "$dev_root\$hostname")) {
    if (!(Test-Path "$cache\$filename")) {
      File-Get $url $cache
    }
    7z x "$cache\$filename" -o"$dev_root"
    rename-item "$dev_root\wordpress" "$dev_root\$hostname"
    copy-item "$dev_root\$hostname\wp-config-sample.php"  "$dev_root\$hostname\wp-config.php"
  } else {
    Write-Output "$dev_root\$hostname already exists.`n"
    if (Prompt-Del-Existing-Dir "$dev_root\$hostname") {
      Wordpress-Download $hostname
    }
  }
}

function Wordpress-Install($hostname) {
  $cache = "$dev_root\.cache"
  $password = Gen-Password
  $dbName = Wordpress-DbName $hostname

  if ( !(Test-Path "$cache\$filename") ) {
    File-Get $url $cache
  }

  Wordpress-Download $hostname

  File-ContentsReplace "$dev_root\$hostname\wp-config.php" "database_name_here" $dbName
  File-ContentsReplace "$dev_root\$hostname\wp-config.php" "username_here" $dbName
  File-ContentsReplace "$dev_root\$hostname\wp-config.php" "password_here" $password

  MySQL-SetupDB $dbName $password
  IIS-Host-Add $hostname
  Certificate-Host-Generate $hostname
  IIS-HostBinding $hostname
}

function Wordpress-UnInstall($hostname) {
  IIS-Host-Remove $hostname
  $dbName = Wordpress-DbName $hostname
  MySQL-RemoveDB $dbName
}
