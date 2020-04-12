using namespace System.Data.SqlClient

# input parameters
param
(
    [String]$ConnectionString,
    [String]$SqlProcedure,
    [String]$DeployDir,
    [String]$DeployScriptNameFormat,
    [Switch]$OnlyScriptCommands,
    [Switch]$NotScriptCommands
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$localBranch, $remoteBranch = git rev-parse --abbrev-ref HEAD '@{upstream}'

try
{
    if (!$OnlyScriptCommands.IsPresent)
    {
        $connection = New-Object SqlConnection $ConnectionString
        $connection.Open()
    
        $tran = $connection.BeginTransaction()
    }

    $command = New-Object SqlCommand $SqlProcedure, $connection, $tran
    $command.CommandType = [System.Data.CommandType]::StoredProcedure

    $param = $command.Parameters.Add((New-Object SqlParameter))
    $param.ParameterName = $null

    # execute sql stored procedure for modified sql objects
    foreach ($file in git diff $remoteBranch $localBranch --name-only --diff-filter=AMR -- '*.sql')
    {
        $sqlObjectPattern = '(?<=(^|\s)(CREATE|ALTER)\s+(PROCEDURE|PROC|FUNCTION|VIEW|TRIGGER)\s+(?!\s))((\[.+?\]|.+?)\.)?(\[.+?\]|.+?(?=[\s\(]))'
        $sqlObject = (Get-Content "$file" -Raw | Select-String -Pattern "$sqlObjectPattern").Matches.Value

        if ($null -ne $sqlObject)
        {
            $param.Value = $sqlObject

            if (!$OnlyScriptCommands.IsPresent)
            {
                $command.ExecuteNonQuery() | Out-Null
            }

            if (!$NotScriptCommands.IsPresent)
            {
                $deployScript += "exec $($command.CommandText) N'$($param.Value.Replace("'", "''"))'"+ [System.Environment]::NewLine
            }
        }
    }

    if ($null -ne $deployScript)
    {
        $deployScriptName = "$DeployScriptNameFormat.sql" -f (Get-Date)

        New-Item -ItemType File -Force -Path "$DeployDir/$localBranch" -Name "$deployScriptName" -Value "$deployScript" -ErrorAction Stop | Out-Null
    }

    if (!$OnlyScriptCommands.IsPresent)
    {
        $tran.Commit()
    }
}
catch
{
    if ($null -ne $tran)
    {
        $tran.Rollback()
    }

    throw
}
finally
{
    if ($null -ne $connection)
    {
        $connection.Close();
    }
}
