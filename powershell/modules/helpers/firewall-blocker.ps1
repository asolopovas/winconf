function ObjectStore {
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param (
        [Parameter(ParameterSetName = 'Add')]
        [hashtable]$Add,

        [Parameter(ParameterSetName = 'Action')]
        [switch]$Get,

        [Parameter(ParameterSetName = 'Action')]
        [switch]$Exist,

        [Parameter(ParameterSetName = 'Remove')]
        $RemoveById = $false,

        [Parameter(ParameterSetName = 'Print')]
        [switch]$Print,

        [Parameter(ParameterSetName = 'Clear')]
        [switch]$Clear,

        [Parameter(ParameterSetName = 'Action')]
        [string]$PropertyName,

        [Parameter(ParameterSetName = 'Action')]
        [string]$PropertyValue
    )

    $configPath = Join-Path -Path $env:APPDATA -ChildPath "ObjectStore.json"

    function Read-ObjectStore {
        if (Test-Path -Path $configPath) {
            return (Get-Content -Path $configPath | ConvertFrom-Json)
        }
        else {
            return @()
        }
    }

    function Write-ObjectStore ($data) {
        ConvertTo-Json $data | Set-Content -Path $configPath
    }

    $global:ObjectStore = Read-ObjectStore

    if ($PSCmdlet.ParameterSetName -eq 'Add') {
        # Check if the object exists
        $objectExists = $global:ObjectStore | Where-Object { $_.ID -eq $Add.ID }

        # Add the object only if it does not exist
        if (-not $objectExists) {
            Write-Host "Adding object --------------------------"
            $Add
            Write-Host "----------------------------------------"

            $global:ObjectStore = @($global:ObjectStore) + $Add
            Write-ObjectStore -data $global:ObjectStore
        }
    }
    # New RemoveById block
    if ($PSCmdlet.ParameterSetName -eq 'Remove') {
        Write-Host "Removing object: $removeById"
        $global:ObjectStore = $global:ObjectStore | Where-Object { $_.ID -ne $RemoveById }
        Write-ObjectStore -data $global:ObjectStore
    }


    if ($Get) {
        $foundObject = $global:ObjectStore | Where-Object { $_.$PropertyName -eq $PropertyValue }
        return $foundObject
    }

    if ($Exist) {
        $foundObject = $global:ObjectStore | Where-Object { $_.$PropertyName -eq $PropertyValue }
        return ($null -ne $foundObject)
    }

    if ($Print) {
        if ($global:ObjectStore -eq @()) {
            Write-Host "Store is Empty"
        }
        else {
            $global:ObjectStore | Format-Table | Out-String | Write-Host
        }
    }

    if ($Clear) {
        $global:ObjectStore = @()
        Write-ObjectStore -data $global:ObjectStore
    }
}

function ExecutablesStore($action = "list", $item = $null, $status = "Blocked", $id = $null ) {
    $appData = [Environment]::GetFolderPath("LocalApplicationData")
    $configPath = Join-Path -Path $appData -ChildPath "LynWinConf"
    $jsonPath = Join-Path -Path $configPath -ChildPath "settings.json"

    if (!(Test-Path -Path $configPath)) {
        New-Item -Path $configPath -ItemType Directory -Force
    }

    if (!(Test-Path -Path $jsonPath)) {
        New-Item -Path $jsonPath -ItemType File -Force
        ConvertTo-Json @() | Set-Content -Path $jsonPath
    }

    $executables = @(Get-Content -Path $jsonPath | ConvertFrom-Json)

    if ($action -eq "get" ) {
        if ( $null -ne $id) {
            return $executables | Where-Object { $_.ID -eq $id }
        }
        else {
            Write-Host "Invalid ID. Please provide a valid ID."
        }
    }

    if ($action -eq "add" -and $null -ne $item -and (! $executables | Where-Object { $_.FullPath -eq $item.FullName })) {
        $id = ($executables | Measure-Object).Count
        $object = @{
            ID       = $id
            FullPath = $item.FullName
            Status   = $status
        }
        ObjectStore -Add $object
        return $true
    }

    if ($action -eq "remove") {
        ObjectStore -Remove $item
        $executables = $executables | Where-Object { $_.FullPath -ne $item.FullName }
    }

    if ($action -eq "list") {
        ObjectStore -Print
    }

    if ($action -eq "clear") {
        ObjectStore -Clear
    }
}


function firewallBlocker([string]$action, [string]$target = "*", [int]$depth = 0, [int]$id = 0) {
    $prefix = Format-String snakecase ([io.path]::GetFileNameWithoutExtension((Get-Location).Path))

    if ($action -eq "block") {
        if ($target -eq "*") {
            Get-ChildItem -Path (Get-Location).Path -Recurse -Filter "*.exe" -Depth $depth | Foreach-Object {
                $object =
                if (! (ExecutablesStore exist $_)) {
                    ExecutablesStore add $_ Blocked
                    Add-FirewallRule $_.FullName $prefix
                }
            }
            return
        }

        if (Test-Path -Path $target -PathType Leaf) {
            if (! (ExecutablesStore exist $target)) {
                ExecutablesStore add @{ FullPath = $target.FullName }
                Add-FirewallRule $target $prefix
            }
            return
        }

        Write-Host "Invalid target. Please provide a valid target (* or filepath)."
        return
    }

    if ($action -eq "unblock") {
        if ($target -eq "*") {
            Get-ChildItem -Path (Get-Location).Path -Recurse -Filter "*.exe" -Depth $depth | Foreach-Object {
                ExecutablesStore remove $_
                Remove-FirewallRule $_.FullName $prefix
            }
            return
        }

        if (Test-Path -Path $target -PathType Leaf) {
            if (ExecutablesStore exist $target) {
                ExecutablesStore remove $target
                Remove-FirewallRule $target $prefix
            }
            return
        }

        Write-Host "Invalid target. Please provide a valid target (* or filepath)."
        return
    }

    if ($action -eq "list") {
        if ($executables.Count -eq 0) {
            Write-Host "No executables in the list."
        }
        else {
            $executables
        }
        return
    }

    if ($action -eq "removeById") {
        if ($id -ge 0) {
            $selectedFile = ExecutablesStore get -id $id
            if ($selectedFile) {
                Remove-FirewallRule $selectedFile.FullPath $prefix
            }
            else {
                Write-Host "ID not found. Please provide a valid ID."
            }
        }
        else {
            Write-Host "Please provide a valid ID for the removeById action."
        }
        return
    }

    if ($action -eq "remove") {
        $executables = ExecutablesStore list
        if ($target -eq "*") {
            foreach ($exe in $executables) {
                FBlocker removeById -id $exe.ID
            }
            ExecutablesStore clear
            return
        }

        if (Test-Path -Path $target -PathType Leaf) {
            $selectedFile = $executables | Where-Object { $_.FullPath -eq $target.FullName }
            FBlocker removeById -id $selectedFile.ID
            return
        }

        Write-Host "Invalid target. Please provide a valid target (* or filepath)."
        return

    }

    Write-Host "Unknown action. Please provide a valid action (block, unblock, list, or toggle)."

}
