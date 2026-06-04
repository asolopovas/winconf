---
name: powershell-windows
description: "PowerShell Windows traps: errors, paths, encoding, JSON, native commands, safe functions."
risk: medium
source: microsoft-docs-context7-stackoverflow-poshcode
date_added: "2026-02-27"
updated: "2026-06-03"
---

# PowerShell Windows

Use for Windows PowerShell 5.1 or PowerShell 7 on Windows.

Use as a checklist: start with Baseline, then the matching section.

## Baseline

```powershell
[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$script_dir = $PSScriptRoot
if (-not $script_dir) {
    $script_dir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
```

- ASCII-only scripts and output: `[OK]`, `[WARN]`, `[ERROR]`.
- Full cmdlet names, named parameters, no aliases in scripts.
- Data: implicit output or `Write-Output`. Logs: verbose/warning/error streams. UI: `Write-Host`.
- Test with `pwsh` and/or `powershell.exe` as required, always with `-NoProfile -NonInteractive`.
- Avoid `Set-StrictMode -Version Latest`; new runtimes can add stricter rules.

## Output semantics

Functions output every success-stream write. `return` only exits scope.

```powershell
[void]$list.Add($item)
$result = Invoke-Thing
$result
```

- Capture or suppress incidental output from `.Add()`, commands, scriptblocks, and helpers.
- Use `[void]...` or `... | Out-Null` for unwanted output.
- Use unary comma or `Write-Output -NoEnumerate` when an array must be one pipeline object.

## Errors and exits

- `try` and `catch` catch terminating errors only.
- Cmdlet errors are often non-terminating. Use `$ErrorActionPreference = 'Stop'` or `-ErrorAction Stop`.
- Native tools need exit-code checks: `$LASTEXITCODE`.
- `$?` is last pipeline success, not a native exit code.
- No empty `catch`; add context and rethrow or exit.

```powershell
try {
    Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
}
catch {
    throw "Failed to remove '$path': $($_.Exception.Message)"
}

& $exe @args
if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code $LASTEXITCODE: $exe"
}
```

## Conditions and operators

Cmdlet calls are not expressions inside boolean operators. Wrap each call.

```powershell
if ((Test-Path -LiteralPath $a) -or (Test-Path -LiteralPath $b)) {
    'found'
}
```

- Put `$null` on the left: `$null -eq $value`.
- `-eq`, `-like`, `-contains` ignore case. Use `-ceq`, `-clike`, `-ccontains` when needed.
- Array comparisons return matches, not always Boolean. Use `@($items).Count` for cardinality.
- Use `-and`, `-or`, `-not` for Windows PowerShell 5.1 compatibility. `&&` and `||` require PowerShell 7.

## Strings, paths, native commands

- Single quotes are literal. Double quotes expand.
- Use `$()` for expressions in strings and `${name}` before `:` or adjacent name characters.
- Avoid backtick line continuation. Use splatting or natural breaks.
- Use splatting for long calls: `$p = @{ Name = $name }; Invoke-Thing @p`.
- Use `$PSScriptRoot`, `Join-Path`, `-LiteralPath`. Use `-Path` only for intended wildcards.
- Invoke executable paths with `&`.
- Prefer argument arrays: `& $exe @args`.
- Native quote parsing differs in 5.1 vs 7. Use `--%` only for Windows-specific literal parsing.
- Prefer `-File` for scripts. Use `-Command` for code strings. Put either last; following args belong to it.

```powershell
$config_path = Join-Path $PSScriptRoot 'config.json'
& 'C:\Program Files\Tool\tool.exe' '--flag' $config_path
```

## Collections and JSON

- Use `@(...)` when command output may be zero, one, or many items.
- `$array += $item` copies arrays; use only for small lists. For loops use generic List.
- Hashtables are unordered. Use `[ordered]@{}` when order matters.
- Use `[pscustomobject][ordered]@{}` for structured output.
- Enumerate hashtables with `.GetEnumerator()`.
- `ConvertTo-Json` default depth is 2. Always set `-Depth`.
- Pipeline input enumerates arrays; JSON may collapse single-item arrays. For shape, use args or `-AsArray`.
- Use `Get-Content -Raw | ConvertFrom-Json`.
- Use `ConvertFrom-Json -NoEnumerate` to preserve single-element arrays on round trip.

```powershell
$items = @(Get-ChildItem -LiteralPath $dir)
$out = [pscustomobject][ordered]@{ Path = $dir; Count = $items.Count }
$out | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $json_path -Encoding UTF8
```

## Advanced functions

```powershell
function Remove-Thing {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    process {
        if ($PSCmdlet.ShouldProcess($Path, 'Remove')) {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        }
    }
}
```

- `CmdletBinding()` adds common parameters; do not redefine them.
- Use approved verbs for public functions.
- Use `SupportsShouldProcess` for mutations: `New`, `Set`, `Update`, `Remove`, `Clear`, `Start`, `Stop`.
- If `SupportsShouldProcess` is declared, call `$PSCmdlet.ShouldProcess()` close to the mutation.
- Pipeline parameters belong with a `process` block.
- Forward bound parameters with `@PSBoundParameters`; remove keys before overriding.

## Windows details

- Windows PowerShell 5.1 may read UTF-8 without BOM as ANSI. Keep ASCII, or use UTF-8 BOM for non-ASCII.
- PowerShell 6+ defaults to UTF-8 without BOM.
- Execution policy is not security. Avoid machine policy changes. Use process scope or `Unblock-File`.
- Prefer CIM over old WMI cmdlets.
- PowerShell 7 WinPS compatibility can return deserialized objects without methods.
- Scope writes are local by default in functions. Use `script:` only intentionally.
- PowerShell 7.4 preserves native binary redirection. Avoid `>` for binary data in 5.1.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\script.ps1
Unblock-File -LiteralPath .\script.ps1
```

## Validation

```powershell
$errors = $null
$tokens = $null
[System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null
if ($errors.Count -gt 0) { $errors | Format-List *; exit 1 }

Invoke-ScriptAnalyzer -Path . -Recurse
pwsh -NoProfile -NonInteractive -File .\script.ps1
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\script.ps1
```

## Sources

Microsoft Learn, Context7, Stack Overflow, PoshCode.
