function Firewall-DisablePathExecutables($path) {
  $prefix = String-To camelCase (get-item $path).Parent.Name
  Get-ChildItem -Path $path -Recurse -Filter "*.exe" | Foreach-Object { Firewall-Rule $_.FullName $prefix }
 }

 function Firewall-Rule ([string] $programName, [string]$prefix, [switch]$allow = $false) {
   $displayName = Get-RootName $programName
   $name = [string]::Concat($prefix, $displayName)
   $exist = Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue
   if ($exist.Count -gt 0 ) { return "Rule $displayName already present" }
   $action = IIf $allow "Allow" "Block"
   New-NetFirewallRule -DisplayName $name -Direction Inbound -Program $programName -Action $action
   New-NetFirewallRule -DisplayName $name -Direction Outbound -Program $programName -Action $action
 }

function Defender-Exclude($path) {
  Add-MpPreference -ExclusionPath $path
}

 Export-ModuleMember -Function Firewall-DisablePathExecutables, Firewall-Rule, Defender-Exclude
