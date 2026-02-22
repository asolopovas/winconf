function ga { git commit --amend }
function gs { git status }
function gb { git branch }
function gc {
    param([string]$message)
    git add -A
    git commit -m $message
}
function gg { git log }
function gd { git diff }
function gk { 
    param([string]$branch)
    git checkout $branch
}
function gt { git tag }

function gp { git push }
function gpo { git push origin }
function gpf { git push --force }
function gl { git pull }

function gsclone { 
    param([string]$repo)
    git clone "git@github.com:asolopovas/$repo"
}
function ghclone { 
    param([string]$repo)
    git clone "https://github.com/asolopovas/$repo"
}

function gundo { git reset --hard HEAD~1 }
function nah { 
    git reset --hard
    git clean -fd
}
function bfg { 
    param([string[]]$args)
    $bfgPath = Join-Path $env:LOCALAPPDATA 'Programs\bfg\bfg.jar'
    $bfgDir = Split-Path $bfgPath -Parent
    
    if (-not (Test-Path $bfgPath)) {
        Write-Host "BFG not found. Downloading..." -ForegroundColor Yellow
        if (-not (Test-Path $bfgDir)) {
            New-Item -ItemType Directory -Path $bfgDir -Force | Out-Null
        }
        try {
            Invoke-WebRequest -Uri "https://repo1.maven.org/maven2/com/madgag/bfg/1.15.0/bfg-1.15.0.jar" -OutFile $bfgPath
            Write-Host "BFG downloaded successfully!" -ForegroundColor Green
        } catch {
            Write-Error "Failed to download BFG: $($_.Exception.Message)"
            return
        }
    }
    
    java -jar $bfgPath @args
}

function gw {
    git add -A
    $commitMessage = Read-Host "Enter commit message"
    if (-not [string]::IsNullOrWhiteSpace($commitMessage)) {
        git commit -m "$commitMessage"
    }
    else {
        git commit -m "save"
    }
}