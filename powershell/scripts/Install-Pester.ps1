$module = "C:\Program Files\WindowsPowerShell\Modules\Pester"
takeown /F $module /A /R
icacls $module /reset
icacls $module /grant Administrators:'F' /inheritance:d /T
Remove-Item -Path $Module -Recurse -Force -Confirm:$false

Install-Module -Name Pester -Force
