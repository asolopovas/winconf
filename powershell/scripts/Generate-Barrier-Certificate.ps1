$cert = New-SelfSignedCertificate -DnsName Barrier -KeyExportPolicy Exportable

# Public key to Base64
$CertBase64 = [System.Convert]::ToBase64String($cert.RawData, 'InsertLineBreaks')

# Private key to Base64
$RSACng = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
$KeyBytes = $RSACng.Key.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)
$KeyBase64 = [System.Convert]::ToBase64String($KeyBytes, [System.Base64FormattingOptions]::InsertLineBreaks)

# Put it all together
$Pem = @"
-----BEGIN PRIVATE KEY-----
$KeyBase64
-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
$CertBase64
-----END CERTIFICATE-----
"@

# Output to file
$Pem | Out-File -FilePath C:\Users\Andrius\AppData\Local\Barrier\SSL\Barrier.pem -Encoding Ascii
