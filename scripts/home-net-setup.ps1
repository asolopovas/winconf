[CmdletBinding()]
param(
    [string]$SourceAlias = "router",
    [string]$TargetAlias = "nas-admin",
    [string]$DnsHostAlias = "",
    [string]$Domain = "",
    [string]$TargetIp = "192.168.1.100",
    [string]$RemoteCertPath = "",
    [string]$RemoteKeyPath = "",
    [string]$RemoteChainPath = "",
    [string]$InstallDir = "/share/Public/cert-sync",
    [string]$IdentityPath = "$env:USERPROFILE\.ssh\id_cert_sync",
    [int]$JellyfinHttpsPort = 8920,
    [int]$QbittorrentWebPort = 6363,
    [switch]$Update,
    [switch]$FixJellyfinThumbnails,
    [switch]$SkipSourceKeyInstall,
    [switch]$SkipDns,
    [switch]$SkipServices
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Read-Required([string]$Name, [string]$Value, [string]$Prompt) {
    if (-not [string]::IsNullOrWhiteSpace($Value)) { return $Value }
    $answer = Read-Host $Prompt
    if ([string]::IsNullOrWhiteSpace($answer)) { throw "$Name is required" }
    return $answer.Trim()
}

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }

if ([string]::IsNullOrWhiteSpace($DnsHostAlias)) { $DnsHostAlias = $SourceAlias }

$Domain = Read-Required "Domain" $Domain "Certificate DNS name"
$RemoteCertPath = Read-Required "RemoteCertPath" $RemoteCertPath "Remote fullchain/cert path on cert source"
$RemoteKeyPath = Read-Required "RemoteKeyPath" $RemoteKeyPath "Remote private key path on cert source"
if (-not $PSBoundParameters.ContainsKey("RemoteChainPath")) {
    $RemoteChainPath = (Read-Host "Remote chain path on cert source, or blank if fullchain includes it").Trim()
}

$certArgs = @{
    SourceAlias = $SourceAlias
    TargetAlias = $TargetAlias
    RemoteCertPath = $RemoteCertPath
    RemoteKeyPath = $RemoteKeyPath
    RemoteChainPath = $RemoteChainPath
    InstallDir = $InstallDir
    IdentityPath = $IdentityPath
}
if (-not $SkipSourceKeyInstall) { $certArgs.InstallSourceAuthorizedKey = $true }
& (Join-Path $scriptDir "inst-lan-cert-sync.ps1") @certArgs

if (-not $SkipDns) {
    & (Join-Path $scriptDir "inst-lan-dns-override.ps1") -DnsHostAlias $DnsHostAlias -Domain $Domain -TargetIp $TargetIp
}

if (-not $SkipServices) {
    $serviceArgs = @{
        NasAlias = $TargetAlias
        Domain = $Domain
        SyncDir = $InstallDir
        JellyfinHttpsPort = $JellyfinHttpsPort
        QbittorrentWebPort = $QbittorrentWebPort
    }
    if ($Update) { $serviceArgs.Update = $true }
    if ($FixJellyfinThumbnails) { $serviceArgs.FixJellyfinThumbnails = $true }
    & (Join-Path $scriptDir "inst-service-certs.ps1") @serviceArgs
}

Write-Host "[OK] home network setup complete"
