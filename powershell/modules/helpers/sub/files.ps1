function Sym-Link($src, $target) {
  New-Item -ItemType SymbolicLink -Path $src -Target $target
}

function Hard-Link($src, $target) {
  New-Item -ItemType HardLink -Name $src -Value $target
}

function Test-IsSymLink([string]$path) {
  $file = Get-Item $path -Force -ea SilentlyContinue
  return [bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Touch-File($file) {
  if ($file -eq $null) {
    throw "No filename supplied"
  }

  if (Test-Path $file) {
    (Get-ChildItem $file).LastWriteTime = Get-Date
  }
  else {
    New-Item -Name $file -ItemType File
  }
}

function File-ContentsReplace($path, $needle, $value) {
  $file = Get-Content $path
  $file.replace($needle, $value) | Set-Content $path
}

function File-Get($url, $path = '') {
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

function Sync-Config ($src, $target) {
  if (Test-IsSymLink($src)) {
    Write-Output "Syncing Existing Config ... `r`n"
    New-Item -ItemType SymbolicLink -Path $src -Target $target -Force

    return
  }
  elseif (Test-Path $src) {
    Write-Output "Removing Existing Config ... `r`n"
    Remove-Item -Recurse -Force $src
    New-Item -ItemType SymbolicLink -Path $src -Target $target -Force

    return
  }
  else {
    Write-Output "Linking Config ... `r`n"

    if (!(Test-Path $target)) {
      Write-Output "$target does not exist"
     return
    }

    New-Item -ItemType SymbolicLink -Path $src -Target $target -Force

    return
  }
}

Export-ModuleMember -Function Sym-Link, Hard-Link, Test-IsSymLink, Touch-File, File-ContentsReplace, File-Get, Sync-Config
