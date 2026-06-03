$ErrorActionPreference = "Stop"

$cert = New-SelfSignedCertificate -DnsName Barrier -KeyExportPolicy Exportable
$certBase64 = [Convert]::ToBase64String($cert.RawData, [Base64FormattingOptions]::InsertLineBreaks)
$key = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
$keyBytes = $key.Key.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)
$keyBase64 = [Convert]::ToBase64String($keyBytes, [Base64FormattingOptions]::InsertLineBreaks)
$pem = @"
-----BEGIN PRIVATE KEY-----
$keyBase64
-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
$certBase64
-----END CERTIFICATE-----
"@

$dirPath = Join-Path $env:LOCALAPPDATA "Barrier\SSL"
New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
$pem | Out-File -FilePath (Join-Path $dirPath "Barrier.pem") -Encoding Ascii
