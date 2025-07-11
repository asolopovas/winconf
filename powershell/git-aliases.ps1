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
function gp { git push }
function gpo { git push origin }
function gundo { git reset --hard HEAD~1 }
function gpf { git push --force }
function gl { git pull }
function gk { 
    param([string]$branch)
    git checkout $branch
}
function gsclone { 
    param([string]$repo)
    git clone "git@github.com:asolopovas/$repo"
}
function ghclone { 
    param([string]$repo)
    git clone "https://github.com/asolopovas/$repo"
}
function bfg { 
    param([string[]]$args)
    java -jar "$env:USERPROFILE\.local\bin\bfg.jar" @args
}
function nah { 
    git reset --hard
    git clean -fd
}
function gt { git tag }