function Convert-ToUxinEndings {
  Get-ChildItem * | ForEach-Object {
    # get the contents and replace line breaks by U+000A
    $contents = [IO.File]::ReadAllText($_) -replace "`r`n?", "`n"
    # create UTF-8 encoding without signature
    $utf8 = New-Object System.Text.UTF8Encoding $false
    # write the text back
    [IO.File]::WriteAllText($_, $contents, $utf8)
  }
}

function Convert-ExcelToCsv ($File) {

  $excelFile = "$pwd\" + $File.Name
  $Excel = New-Object -ComObject Excel.Application
  $Excel.Visible = $false
  $Excel.DisplayAlerts = $false
  $wb = $Excel.Workbooks.Open($excelFile)
  foreach ($ws in $wb.Worksheets) {
    $ws.SaveAs("$pwd\csv\" + $File.BaseName + ".csv", 6)
  }
  $Excel.Quit()
}

function  Convert-ExcelToCsvDir {
  New-Item $pwd\csv -type Directory
  $items = Get-ChildItem -Recurse | Where-Object {!($_.PSIsContainer)}

  foreach ($item in $items) {
    ExcelCSV($item)
  }
}

function String-To([string]$case, [string]$string) {
  return node "$PSScriptRoot\..\js\string-case.js" $case $string
}

Export-ModuleMember -Function Convert-ToUxinEndings, Convert-ExcelToCsv, Convert-ExcelToCsvDir, String-To
