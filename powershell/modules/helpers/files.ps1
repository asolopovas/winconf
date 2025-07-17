function New-SymLink($src, $target) {
    New-Item -ItemType SymbolicLink -Path $target -Target $src
}

function New-HardLink($src, $target) {
    New-Item -ItemType HardLink -Name $src -Value $target
}

function New-File($file) {
    if ($null -eq $file) {
        throw "No filename supplied"
    }

    if (Test-Path $file) {
        (Get-ChildItem $file).LastWriteTime = Get-Date
    }
    else {
        New-Item -Name $file -ItemType File
    }
}

function Test-IsSymLink([string]$path) {
    $file = Get-Item $path -Force -ea SilentlyContinue
    return [bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Find-Replace($path, $needle, $value) {
    $file = Get-Content $path
    $file.replace($needle, $value) | Set-Content $path
}

function Get-File($url, $path = '') {
    $exploded_url = $url -Split "/"
    $output = (Resolve-Path .\).Path + '\' + $exploded_url[-1]
    $start_time = Get-Date

    Start-BitsTransfer $url $output
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    if ($path) {
        if ( !(Test-Path $path) ) { New-Item -Type Directory $path }
        Move-Item $output $path
    }
}
