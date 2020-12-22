# ExecuteNonQuery - Used for queries that don't return any real information, such as an INSERT, UPDATE, or DELETE.
# ExecuteReader - Used for normal queries that return multiple values. Results need to be received into MySqlDataReader object.
# ExecuteScalar - Used for normal queries that return a single. The result needs to be received into a variable.

function MySQL-GenerateConnString ([string]$user,[string]$pass = "",[string]$MySQLHost = "127.0.0.1",[string]$database) {
  $output = "server=$MySQLHost;port=3306;uid=$user;"
  if ($pass) {
    $output += "pwd=$pass;"
  }
  if ($database) {
     $output += "database=$database;"
  }
  $output += "Pooling=False"
  return $output
}

function MySQL-Connect([string]$user,[string]$pass,[string]$MySQLHost,[string]$database) {
  # Load MySQL .NET Connector Objects
  [void][system.reflection.Assembly]::LoadWithPartialName("MySql.Data")

  # Open Connection
  $connStr = MySQL-GenerateConnString $user $pass
  $conn = New-Object MySql.Data.MySqlClient.MySqlConnection($connStr)
  $conn.Open()
  return $conn
}

function MySQL-Close($conn) {
  $conn.Close()
}

# Does not return value
function MySQL-NonQuery($conn, [string]$query) {
  $command = $conn.CreateCommand()                  # Create command object
  $command.CommandText = $query                     # Load query into object
  $RowsInserted = $command.ExecuteNonQuery()        # Execute command
  $command.Dispose()                                # Dispose of command object
}

function MySQL-Reader($conn, [string]$query) {
  # NonQuery - Insert/Update/Delete query where no return data is required
  $cmd = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $conn)         # Create SQL command
  $dataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($cmd)      # Create data adapter from query command
  $dataSet = New-Object System.Data.DataSet                                    # Create dataset
  $dataAdapter.Fill($dataSet, "data")                                          # Fill dataset from data adapter, with name "data"
  $cmd.Dispose()
  return $dataSet.Tables["data"]                                               # Returns an array of results
}

function MySQL-Scalar($conn, [string]$query) {
    # Scalar - Select etc query where a single value of return data is expected
    $cmd = $conn.CreateCommand()                                             # Create command object
    $cmd.CommandText = $query                                                   # Load query into object
   return $cmd.ExecuteScalar()                                                        # Execute command
}

function MySQL-SetupDB($db, $passwd) {
  $conn = MySQL-Connect root

  if ([string]::IsNullOrEmpty($db)) {
    Write-Host "`$db argument is empty"
  }

  $exist = MySQL-Scalar $conn "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = `'$db`';"
  if ( !( $exist ) ) {
    $queries = @(
      "CREATE DATABASE $db;",
      "CREATE USER $db@'localhost' IDENTIFIED BY `'$passwd`';",
      "GRANT ALL PRIVILEGES ON $db.* TO $db@'localhost';",
      "FLUSH PRIVILEGES;"
    )

    foreach ($query in $queries) {
     MySQL-NonQuery $conn $query
    }
  }
}
function MySQL-RemoveDB($db) {
  $conn = MySQL-Connect root

  if ([string]::IsNullOrEmpty($db)) {
    Write-Host "`$db argument is empty"
  }

  $warning = Prompt-User "Database and User `"$db`" will be removed permanently from MySQL" "Do you want to continue?"
  if ( $warning ) {
    $queries = @(
      "DROP DATABASE $db;",
      "DROP USER `'$db`'@`'localhost`';",
      "FLUSH PRIVILEGES;"
    )

    foreach ($query in $queries) {
     MySQL-NonQuery $conn $query
    }
  }

}
