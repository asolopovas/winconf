$Password = Read-Host -Prompt "Provide your new account password" -AsSecureString
Set-LocalUser -Name "$env:UserName" -Password $Password
Clear-Variable "Password"
