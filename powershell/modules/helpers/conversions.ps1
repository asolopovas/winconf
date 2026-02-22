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

function Format-String {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Case,

        [Parameter(Position = 1)]
        [string]$String
    )

    if (!$String) {
        Write-Error "String argument is null or empty"
        return
    }

    switch ($Case) {
        "camelcase" {
            $String = $String -replace "([a-z])([A-Z])", '$1 $2'
            $String = $String -replace " ", ""
            $String = $String.Substring(0,1).ToLower() + $String.Substring(1)
            return $String
        }

        "pascalcase" {
            $String = $String -replace "([a-z])([A-Z])", '$1 $2'
            $String = $String -replace " ", ""
            $String = $String.Substring(0,1).ToUpper() + $String.Substring(1)
            return $String
        }

        "snakecase" {
            $String = $String.ToLower()
            $String = $String -replace " ", "_"
            return $String
        }

        default {
            Write-Error "Invalid case argument: $Case"
            return
        }
    }
}
