Import-Module '../modules/helpers/helpers.psm1' -WarningAction SilentlyContinue

Describe 'Get-RootName' {
  $result = Get-RootName 'c:\code\test.test'

  it 'should return "test"' {
    $result | should be "test"
  }
}
