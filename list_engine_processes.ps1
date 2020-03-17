param (
    [string]$dbServer = $(throw "-dbServer is required")
)




$engines = Invoke-Sqlcmd -Query "select id, substring(serveruri, 8, len(serveruri) - 57) as hostname, servername from engineservers where IsBlocked = 0 order by hostname asc" -Database "cxdb" -ServerInstance $dbServer

foreach ( $engine in $engines ) {
    Write-Host $engine.ServerName "-" $engine.hostname

    $rhost = $engine.hostname;

    $processes = gwmi -ComputerName "$rhost" -Query "select name, commandline, workingsetsize from win32_process where name like 'Cx%'"
    #$processes
    
    foreach ( $proc in $processes ) {
        if ( $proc.name -eq "CxEngineAgent.exe" ) {
            $totalProcCount++;
            $taskID = [regex]::match( $proc.CommandLine, '.*.exe" (\d+)_.*' ).Groups[1].Value
            $sourceID = [regex]::match( $proc.CommandLine, '.*.exe" \d+_(.{36})' ).Groups[1].Value
            #Write-Host $proc.Commandline " -> $taskID, $sourceID"

            Write-Host `t"Scanning: task $taskID, source $sourceID"
        } else {
            $mem = [int]($proc.WorkingSetSize / (1024*1024));
        }
            
    }
    Write-Host `t"Main engine service mem used: $mem MB";
    

    
    #return;
}
