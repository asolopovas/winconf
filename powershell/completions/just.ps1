if (-not $global:__justCompletionCache) {
    $global:__justCompletionCache = @{}
}

function global:ConvertFrom-JustCompletionToken {
    param([string]$Token)

    if (-not $Token) {
        return ''
    }

    if (($Token.Length -ge 2) -and (($Token[0] -eq '"' -and $Token[$Token.Length - 1] -eq '"') -or ($Token[0] -eq "'" -and $Token[$Token.Length - 1] -eq "'"))) {
        return $Token.Substring(1, $Token.Length - 2)
    }

    $Token
}

function global:Find-JustCompletionFile {
    param([string]$Path)

    if (-not $Path) {
        try {
            $Path = (Get-Location).ProviderPath
        } catch {
            return $null
        }
    }

    if (-not $Path) {
        return $null
    }

    try {
        $directory = [System.IO.DirectoryInfo]::new($Path)
    } catch {
        return $null
    }

    if (-not $directory.Exists) {
        return $null
    }

    while ($directory) {
        foreach ($name in @('justfile', 'Justfile', '.justfile')) {
            $candidate = [System.IO.Path]::Combine($directory.FullName, $name)
            if ([System.IO.File]::Exists($candidate)) {
                return $candidate
            }
        }
        $directory = $directory.Parent
    }

    $null
}

function global:Add-JustCompletionName {
    param(
        [System.Collections.Generic.List[string]]$Names,
        [System.Collections.Generic.HashSet[string]]$Seen,
        [string]$Name
    )

    if ($Name -and $Seen.Add($Name)) {
        $Names.Add($Name)
    }
}

function global:Get-JustCompletionNames {
    param([string]$JustfilePath)

    if (-not $JustfilePath) {
        return @()
    }

    try {
        $item = [System.IO.FileInfo]::new($JustfilePath)
        if (-not $item.Exists) {
            return @()
        }
    } catch {
        return @()
    }

    $cacheKey = $item.FullName.ToLowerInvariant()
    $cacheEntry = $global:__justCompletionCache[$cacheKey]
    if ($cacheEntry -and ($cacheEntry.LastWriteTimeUtc -eq $item.LastWriteTimeUtc) -and ($cacheEntry.Length -eq $item.Length)) {
        return $cacheEntry.Names
    }

    $names = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

    try {
        foreach ($line in [System.IO.File]::ReadLines($item.FullName)) {
            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }

            $first = $line[0]
            if ([char]::IsWhiteSpace($first) -or $first -eq '#') {
                continue
            }

            if ($line -match '^alias\s+([A-Za-z0-9_][A-Za-z0-9_-]*)\s*:=') {
                Add-JustCompletionName -Names $names -Seen $seen -Name $Matches[1]
                continue
            }

            $colonIndex = $line.IndexOf(':')
            if ($colonIndex -lt 0) {
                continue
            }

            if (($colonIndex + 1 -lt $line.Length) -and ($line[$colonIndex + 1] -eq '=')) {
                continue
            }

            $prefix = $line.Substring(0, $colonIndex).Trim()
            if ($prefix -match '^(?:@)?([A-Za-z0-9_][A-Za-z0-9_-]*)(?:\s|\(|$)') {
                Add-JustCompletionName -Names $names -Seen $seen -Name $Matches[1]
            }
        }
    } catch {
        return @()
    }

    $result = $names.ToArray()
    $global:__justCompletionCache[$cacheKey] = [pscustomobject]@{
        LastWriteTimeUtc = $item.LastWriteTimeUtc
        Length = $item.Length
        Names = $result
    }

    $result
}

function global:Get-JustCompletionText {
    param([string]$Name)

    if ($Name -match '^[A-Za-z0-9_./-]+$') {
        return $Name
    }

    "'$($Name.Replace("'", "''"))'"
}

function global:Get-JustCompletionPath {
    param([System.Management.Automation.Language.CommandAst]$CommandAst)

    $workingDirectory = $null
    $justfilePath = $null
    $elements = @($CommandAst.CommandElements)

    for ($i = 1; $i -lt $elements.Count; $i++) {
        $token = ConvertFrom-JustCompletionToken $elements[$i].Extent.Text

        if (($token -eq '--working-directory') -or ($token -eq '-d')) {
            if ($i + 1 -lt $elements.Count) {
                $workingDirectory = ConvertFrom-JustCompletionToken $elements[$i + 1].Extent.Text
                $i++
            }
            continue
        }

        if (($token -eq '--justfile') -or ($token -eq '-f')) {
            if ($i + 1 -lt $elements.Count) {
                $justfilePath = ConvertFrom-JustCompletionToken $elements[$i + 1].Extent.Text
                $i++
            }
            continue
        }

        if ($token -like '--working-directory=*') {
            $workingDirectory = $token.Substring(20)
            continue
        }

        if ($token -like '--justfile=*') {
            $justfilePath = $token.Substring(11)
        }
    }

    if ($workingDirectory) {
        try {
            $workingDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($workingDirectory)
        } catch {}
    }

    if ($justfilePath) {
        try {
            if ($workingDirectory -and -not [System.IO.Path]::IsPathRooted($justfilePath)) {
                $justfilePath = [System.IO.Path]::Combine($workingDirectory, $justfilePath)
            } else {
                $justfilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($justfilePath)
            }
        } catch {}

        if ([System.IO.File]::Exists($justfilePath)) {
            return $justfilePath
        }
    }

    Find-JustCompletionFile -Path $workingDirectory
}

Register-ArgumentCompleter -Native -CommandName just, just.exe -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    if ($wordToComplete -like '-*') {
        return
    }

    $justfile = Get-JustCompletionPath -CommandAst $commandAst
    if (-not $justfile) {
        return
    }

    $names = Get-JustCompletionNames -JustfilePath $justfile
    foreach ($name in $names) {
        if (-not $name.StartsWith($wordToComplete, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        $completionText = Get-JustCompletionText -Name $name
        [System.Management.Automation.CompletionResult]::new($completionText, $name, 'ParameterValue', $name)
    }
}
