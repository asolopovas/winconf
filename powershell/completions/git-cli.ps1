if ( Test-CommandExists gh) {
    Invoke-Expression -Command $(gh completion -s powershell | Out-String)
}
