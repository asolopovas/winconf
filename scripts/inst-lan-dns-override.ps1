[CmdletBinding()]
param(
    [string]$DnsHostAlias = "router",
    [string]$Domain = "",
    [string]$TargetIp = "192.168.1.100",
    [switch]$Remove
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

function ConvertTo-ShLiteral([string]$Value) {
    if ($Value.Contains("'")) { throw "Value contains single quote and cannot be safely quoted: $Value" }
    return "'$Value'"
}

if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) { throw "ssh was not found in PATH" }

$Domain = Read-Required -Name "Domain" -Value $Domain -Prompt "Certificate DNS name"
$TargetIp = Read-Required -Name "TargetIp" -Value $TargetIp -Prompt "LAN target IP"
$domainLiteral = ConvertTo-ShLiteral $Domain
$ipLiteral = ConvertTo-ShLiteral $TargetIp

if ($Remove) {
    $remote = "set -eu; f=/jffs/configs/dnsmasq.conf.add; mkdir -p /jffs/configs; touch `$f; grep -vF address=/$domainLiteral/ `$f > /tmp/dns-override.conf.add || true; cp /tmp/dns-override.conf.add `$f; service restart_dnsmasq >/dev/null 2>&1 || true; echo removed $Domain"
}
else {
    $remote = "set -eu; f=/jffs/configs/dnsmasq.conf.add; mkdir -p /jffs/configs; touch `$f; grep -vF address=/$domainLiteral/ `$f > /tmp/dns-override.conf.add || true; echo address=/$domainLiteral/$ipLiteral >> /tmp/dns-override.conf.add; cp /tmp/dns-override.conf.add `$f; nvram set jffs2_scripts=1 >/dev/null 2>&1 || true; nvram commit >/dev/null 2>&1 || true; service restart_dnsmasq >/dev/null 2>&1 || true; echo $Domain resolves to $TargetIp on LAN"
}

& ssh $DnsHostAlias $remote
if ($LASTEXITCODE -ne 0) { throw "ssh $DnsHostAlias failed with exit code $LASTEXITCODE" }
