function CallExecuteSQLScript
{
	[CmdletBinding( )]
    Param([Parameter(Mandatory=$true)][string] $SQLStringPath, [string] $DataBaseName, [string] $DatabaseServer)
    
    if ( $true -eq [string]::IsNullOrWhiteSpace( $DataBaseName ) ) { $DataBaseName = "ODS" }
    if ( $true -eq [string]::IsNullOrWhiteSpace( $DatabaseServer ) ) { $DatabaseServer = "localhost" }

    # We take a string of the format "D:\ATF\Test\DeleteBots.sql|D:\ATF\clearCartonLiftsAndCancelOrders.sql"
    $pathParts = $SQLStringPath.Split("|")
    for($i=0; $i -lt $($($pathParts.length)); $i++)
    {
        ExecuteSQLScript $pathParts[$i] $DatabaseName $DatabaseServer
    }
}

function ExecuteSQLScript  
{
    [CmdletBinding( )]
    Param([Parameter(Mandatory=$true)][string] $ScriptPath, [Parameter(Mandatory=$true)][string] $DatabaseName, [Parameter(Mandatory=$true)][string] $DatabaseServer)

    WriteToInstallLog "Opening connection to Database '$DatabaseName' on Server: '$DatabaseServer'"
    $SQLConnectionObject = new-object system.data.SqlClient.SQLConnection("Data Source=$DatabaseServer;Integrated Security=SSPI;Initial Catalog=$DatabaseName;Connection Timeout=600");
    $SQLConnectionObject.Open();

    # SQLConnectionObject Properties
    $DataSource = $SQLConnectionObject.DataSource;
    WriteToInstallLog "Name of Data Source established by the SQLConnectionObject: $DataSource"
    $Database = $SQLConnectionObject.Database;
    WriteToInstallLog "Name of Database established by the SQLConnectionObject: $Database"

    WriteToInstallLog "Getting the SQL script..."
    $SQLScript = Get-Content $ScriptPath
    WriteToInstallLog "Executing script: '$ScriptPath'"
    WriteToInstallLog "Script contents: '$SQLScript'"

    try
    {
        $SQLCommandObject = New-Object System.Data.SQLClient.SQLCommand($SQLScript, $SQLConnectionObject);
        $SQLCommandExecutionOutput = $SQLCommandObject.ExecuteScalar()
        # We only log the output of ExecuteScalar if the script failed to execute. ExecuteScaler returns nothing if the script is successful.
        if ( $false -eq [string]::IsNullOrWhiteSpace( $SQLCommandExecutionOutput )) { WriteToInstallLog $SQLCommandExecutionOutput }
        WriteToInstallLog "Script Successfully Executed."
    }
    catch
    {
        [system.exception]
        $ExceptionMessage = $_.Exception
        WriteToInstallLog $ExceptionMessage
    }
    finally
    {
        $SQLConnectionObject.Close();
    }
}