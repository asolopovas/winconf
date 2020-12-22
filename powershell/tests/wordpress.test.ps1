# Import-Module ../modules/helpers/helpers.psm1 -WarningAction SilentlyContinue
# Import-Module ../modules/web-utils/web-utils.psm1 -WarningAction SilentlyContinue

Describe 'Site-Root-Name' {
  $result = Site-Root-Name domain-test.com

  it 'should return "domain-test"' {
    $result | should be "domain-test"
  }
}

Describe 'Wordpress-DbName' {
  $result = Wordpress-DbName domain-test.com

  it 'should return domain_test_wp' {
    $result | should be "domain_test_wp"
  }
}
