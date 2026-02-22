function Test-CommandExists {
    param (
        [Parameter(Mandatory)]
        [string]$Command
    )

    [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function SetPermissions {
    param (
        [Parameter(Mandatory)]
        [string]$Dir
    )

    if (-not (Test-Path $Dir)) {
        Write-Error "Path '$Dir' does not exist"
        return
    }

    $acl = Get-Acl $Dir
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $env:UserName, "FullControl", "Allow"
    )
    $acl.SetAccessRule($accessRule)
    Set-Acl $Dir $acl
}

function CreateSymLink {
    param (
        [Parameter(Mandatory)]
        [string]$Src,

        [Parameter(Mandatory)]
        [string]$Target
    )

    Remove-Item -Force -Recurse -Confirm:$false $Src -ErrorAction SilentlyContinue
    New-Item -ItemType SymbolicLink -Path $Src -Target $Target -Force
}
