New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
$removeRegistryKeys = @(
    #"HKCR:\\*\shell\ShareX"
    #"HKCR:\\*\shell\ShareX"
    "HKCR:\Directory\Background\shell\git_shell"
    "HKCR:\Directory\Background\shell\git_gui"
    "HKCR:\Directory\shell\git_shell"
    "HKCR:\Directory\shell\git_gui"
    "HKCR:\Directory\shell\PlayWithVLC"
    "HKCR:\Directory\shell\AddToPlaylistVLC"
    "HKCR:\Directory\shell\ShareX"
    "HKCR:\Directory\shell\CaptureOne"
)

foreach ($key in $removeRegistryKeys) {
    if (Test-Path $key) {
        Remove-Item -Path $key -Recurse -Force -Verbose
    }
}
