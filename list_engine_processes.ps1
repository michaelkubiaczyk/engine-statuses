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
            $match = [regex]::match( $proc.CommandLine, '.*.exe" (\d+)_(.{36})_(.{4})' )
            $taskID = $match.Groups[1].Value
            $sourceID = $match.Groups[2].Value
            $nonce = $match.Groups[3].Value 
            #Write-Host $proc.Commandline " -> $taskID, $sourceID"

            
            $logPath = "\\" + $rhost + "\d$\Program Files\Checkmarx\Checkmarx Engine Server\Engine Server\Scans\" + $taskID + "_" + $sourceID + "_" + $nonce + "\Logs\*"

            
            $lastModified = 0
            $created = 0
            $logup = ""

            Get-ChildItem -Path $logPath | Foreach-Object {
                $lastModified = $_.LastWriteTimeUtc
                $created = $_.CreationTimeUtc
                $diff = New-TimeSpan -Start $lastModified -End (GET-DATE).ToUniversalTime()
                
                if ( $diff.TotalHours -ge 24 ) {
                    $logup = "" + [math]::Round($diff.TotalHours / 24,1) + " days ago"
                } elseif( $diff.TotalMinutes -ge 60 ) {
                    $logup = "" + [math]::Round($diff.TotalMinutes / 60, 1) + " hours ago"
                } else {
                    $logup = "" + [math]::Round($diff.TotalMinutes, 1 ) + " minutes ago"
                }
                
                
            }

            Write-Host `t"Scanning: task $taskID source $sourceID - log last updated $lastModified ($logup), created $created"

        } else {
            $mem = [int]($proc.WorkingSetSize / (1024*1024));
        }
            
    }
    Write-Host `t"Main engine service mem used: $mem MB";
    

    
    #return;
}
