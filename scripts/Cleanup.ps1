New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR

$removeRegistryKeys = @(
    "HKCR:\Directory\Background\shell\git_shell"
    "HKCR:\Directory\Background\shell\git_gui"
    "HKCR:\Directory\shell\git_shell"
    "HKCR:\Directory\shell\git_gui"
    "HKCR:\Directory\shell\ShareX"
    "HKCR:\Directory\shell\CaptureOne"
)

function Remove-RegistryKeys {
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $removeRegistryKeys
    )

    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR

    foreach ($key in $removeRegistryKeys) {
        if (Test-Path $key) {
            Remove-Item -Path $key -Recurse -Force -Verbose
        }
    }
}

Remove-RegistryKeys -removeRegistryKeys $removeRegistryKeys
