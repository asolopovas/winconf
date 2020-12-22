function extFile($domain) {
    $contents = "authorityKeyIdentifier=keyid,issuer`nbasicConstraints=CA:FALSE`nkeyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment`nsubjectAltName = @alt_names`n[alt_names]`nDNS.1 = $domain"
    $tmp = New-TemporaryFile
    $contents | Out-File -Encoding "UTF8" $tmp.FullName
    $MyFile = Get-Content $tmp.FullName
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines($tmp.FullName, $MyFile, $Utf8NoBomEncoding)
    return $tmp.FullName
}

function Certificate-Exist($hostname) {
  $sum = Get-ChildItem Cert:\ -Recurse | Where-Object { $_.Subject -Match $hostname} | Measure-Object
  Return $sum.Count -gt 0
}

function Certificate-Remove($name = '', $path = "Cert:\") {
  if (Certificate-Exist $name) {
    Get-ChildItem $path -Recurse | Where-Object { $_.Subject -Match $name} | ForEach-Object {
      Write-Host "Removing $name Thumbprint: $($_.Thumbprint) from $($_.PSParentPath)";
    }
    Get-ChildItem $path -Recurse | Where-Object { $_.Subject -Match $name} | Remove-Item
  }
}

function Certificate-Import($cert, $path) {
 Import-PfxCertificate -FilePath $cert -CertStoreLocation $path
}

function Certificate-Clean-All() {
  Get-ChildItem Cert:\LocalMachine\WebHosting -Recurse | Remove-Item
  Get-ChildItem Cert:\CurrentUser\Root -Recurse | Where-Object { $_.Subject -Match "RootCA"} | Remove-Item
  if (Test-Path $dev_root_cert) {
    Remove-Item -Recurse $dev_root_cert
  }
  if (Test-Path $dev_host_cert) {
    Remove-Item -Recurse $dev_host_cert
  }
}

function Certificate-Root-Generate() {
  if ( !( Test-Path $dev_root_cert ) ) { New-Item $dev_root_cert  -Type Directory }
  Push-Location $dev_root_cert
    openssl genrsa -des3 -passout pass:default -out rootCA.key 2048
    # required for pem certificate
    # openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 20480 -out rootCA.pem
    openssl req -x509 -new -nodes -passin pass:default -key rootCA.key -sha256 -days 20480 -subj "/C=GB/ST=London/L=London/O=Development/OU=IT Department/CN=Self Signed RootCA/emailAddress=info@lyntouch.com" -out rootCA.crt
    (Get-ChildItem -Path .\rootCA.crt) | Import-Certificate -CertStoreLocation cert:\CurrentUser\Root
  Pop-Location
}

function Certificate-Host-Generate($domain) {
  if ( !(Test-Path $dev_root_cert) ) { New-Item $dev_root_cert -Type Directory }
  if ( !(Test-Path $dev_host_cert) ) { New-Item $dev_host_cert -Type Directory }
  if ( !( Certificate-Exist rootCA ) ) { Certificate-Root-Generate }
if ( Certificate-Exist $domain ) { Return }
  Push-Location  $dev_root_cert
    openssl req -new -sha256 -nodes  -out "$domain.csr" -newkey rsa:2048 -days 20480 -subj "/C=GB/ST=London/L=London/O=$domain/OU=IT Department/CN=$domain Self Signed Certificate/emailAddress=info@$domain"  -keyout "$domain.key"
    $extFile = extFile $domain
    openssl x509 -req -passin pass:default -in "$domain.csr" -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out "$domain.crt" -days 500 -sha256 -extfile $extfile
    openssl pkcs12 -export -passin pass:default  -inkey "$domain.key" -in "$domain.crt" -out "$domain.pfx" -passout pass:
    Move-Item  -Path "$domain.csr", "$domain.crt", "$domain.key", "$domain.pfx" -Destination "$dev_host_cert" -Force
    Certificate-Import "$dev_host_cert\$domain.pfx" Cert:\LocalMachine\WebHosting
  Pop-Location
}

Set-Alias -Name cert-rm    Certificate-Remove
Set-Alias -Name cert-inst  Certificate-Import
Set-Alias -Name cert-clean Certificate-Clean-All

Export-ModuleMember -Alias * -Function *
