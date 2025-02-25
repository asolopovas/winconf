function Remove-ByPattern($pattern) {
  if (!$pattern) {
    Write-Error "Please provide Regular Expression Pattern parameter.  `n
    exmpl. Remove-by-Pattern `"\d{1,3}x?\d{1,3}.jpg`" value"
    return
  }
  $items = Get-ChildItem -recurse | Where {$_.Name -Match $pattern}
  foreach ($item in $items) {
    Write-Output $item
    $Path = $item.FullName;
    Remove-Item $Path;
  }
}
