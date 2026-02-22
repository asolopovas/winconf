function Convert-ToUnixEndings {
    param (
        [Parameter(Mandatory=$false)]
        [string]$extension = '.txt'
    )

    Get-ChildItem *$extension | ForEach-Object {
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
    Convert-ExcelToCsv $item
  }
}

function Format-String([string]$case, [string]$string) {
    if (!$string) {
        Write-Error "String argument is null or empty"
        return
    }

    switch ($case) {
        "camelcase" {
            $string = $string -replace "([a-z])([A-Z])", '$1 $2'
            $string = $string -replace " ", ""
            $string = $string.Substring(0,1).ToLower() + $string.Substring(1)
            return $string
        }

        "pascalcase" {
            $string = $string -replace "([a-z])([A-Z])", '$1 $2'
            $string = $string -replace " ", ""
            $string = $string.Substring(0,1).ToUpper() + $string.Substring(1)
            return $string
        }

        "snakecase" {
            $string = $string.ToLower()
            $string = $string -replace " ", "_"
            return $string
        }

        default {
            Write-Error "Invalid case argument: $case"
            return
        }
    }
}
