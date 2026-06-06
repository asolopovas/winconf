[CmdletBinding()]
param(
    [string]$RouterAlias = "router",
    [string]$Domain = "agreen.ddns.net",
    [string]$NasIp = "192.168.1.100",
    [switch]$Remove
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function ConvertTo-ShLiteral([string]$Value) {
    if ($Value.Contains("'")) {
        throw "Shell value contains single quote and cannot be safely quoted: $Value"
    }
    return "'$Value'"
}

if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    throw "ssh was not found in PATH"
}

$domainLiteral = ConvertTo-ShLiteral $Domain
$ipLiteral = ConvertTo-ShLiteral $NasIp

if ($Remove) {
    $remote = "set -eu; f=/jffs/configs/dnsmasq.conf.add; mkdir -p /jffs/configs; touch `$f; grep -vF address=/$domainLiteral/ `$f > /tmp/router-qnap-dnsmasq.conf.add || true; cp /tmp/router-qnap-dnsmasq.conf.add `$f; service restart_dnsmasq >/dev/null 2>&1 || true; echo removed $Domain"
}
else {
    $remote = "set -eu; f=/jffs/configs/dnsmasq.conf.add; mkdir -p /jffs/configs; touch `$f; grep -vF address=/$domainLiteral/ `$f > /tmp/router-qnap-dnsmasq.conf.add || true; echo address=/$domainLiteral/$ipLiteral >> /tmp/router-qnap-dnsmasq.conf.add; cp /tmp/router-qnap-dnsmasq.conf.add `$f; nvram set jffs2_scripts=1 >/dev/null 2>&1 || true; nvram commit >/dev/null 2>&1 || true; service restart_dnsmasq >/dev/null 2>&1 || true; echo $Domain resolves to $NasIp on LAN"
}

& ssh $RouterAlias $remote
if ($LASTEXITCODE -ne 0) {
    throw "ssh $RouterAlias failed with exit code $LASTEXITCODE"
}
