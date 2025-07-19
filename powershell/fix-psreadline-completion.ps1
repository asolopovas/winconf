# Fix for duplicate cd completions in PSReadLine
# This addresses the visual duplication issue in the completion menu

# Disable menu completion entirely and use classic style to avoid duplicate display
Set-PSReadLineKeyHandler -Key Tab -Function Complete