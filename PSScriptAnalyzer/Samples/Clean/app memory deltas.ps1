## Use ps to measure Application Memory Deltas
## Run '.\\ws_diff [Interval in Seconds] [Process Name] or
## to log all processes continually every 10 seconds -- 'while (1) {.\\WS_diff.ps1 10 cmd >> ps_out.txt }'

# Create args as Variables or Objects
 $sleep_time = $args[0]
#$sleep_time = 10

# Create or define PS_Array. Default is ps is called without args. 
# Then take measurements $now, $then, $count
if ($args[1] -eq $NULL )
    {
    $then = ps | %{$_ | Select Name,ID,WorkingSet,PrivateMemorySize,VirtualMemorySize}
    sleep -seconds $sleep_time
    $now  = ps | %{$_ | Select Name,ID,WorkingSet,PrivateMemorySize,VirtualMemorySize}
    $count = ($now | Select Name).count
    }
else
    {
    $ps_array = ( ps $args[1] )
    $then = ps -inputobject $ps_array | %{$_ | Select Name,ID,WorkingSet,PrivateMemorySize,VirtualMemorySize}
    sleep -seconds $sleep_time
    $now  = ps -inputobject $ps_array | %{$_ | Select Name,ID,WorkingSet,PrivateMemorySize,VirtualMemorySize}
    $count = ($now | Select Name).count
    }

# Declare Sample Time Measurement
# Declare Hours.Minutes.Seconds.Milliseconds in body of loop for more accuracy 
$date = (get-date -format g)

# Write output and find diffs. Check if process has multiple instances first
if ( $count -gt 1 ) 
{
    $array_out = 0..$count |
    %{ 
    $date + "," +
    [DateTime]::UtcNow.TimeOfDay.Hours + ":" + 
    [DateTime]::UtcNow.TimeOfDay.Minutes + ":" + 
    [DateTime]::UtcNow.TimeOfDay.Seconds + ":"  + 
    [DateTime]::UtcNow.TimeOfDay.Milliseconds + "," +
    $sleep_time + "," + $now[$_].Name + "," + $now[$_].ID + "," +
    $now[$_].WorkingSet + "," +
    $now[$_].PrivateMemorySize + "," +
    $now[$_].VirtualMemorySize + "," +
    ( ($now[$_].WorkingSet) - ($then[$_].WorkingSet) ) + "," +
    ( ($now[$_].PrivateMemorySize) - ($then[$_].PrivateMemorySize) ) + "," +
    ( ($now[$_].VirtualMemorySize) - ($then[$_].VirtualMemorySize) )
    }
}

else  
{
    $array_out =
    $date + "," +
    [DateTime]::UtcNow.TimeOfDay.Hours + ":" + 
    [DateTime]::UtcNow.TimeOfDay.Minutes + ":" + 
    [DateTime]::UtcNow.TimeOfDay.Seconds + ":"  + 
    [DateTime]::UtcNow.TimeOfDay.Milliseconds + "," +
    $sleep_time + "," + $now.Name + "," + $now.ID + "," +
    $now.WorkingSet + "," +
    $now.PrivateMemorySize + "," +
    $now.VirtualMemorySize + "," +
    ( ($now.WorkingSet) - ($then.WorkingSet) ) + "," +
    ( ($now.PrivateMemorySize) - ($then.PrivateMemorySize) ) + "," +
    ( ($now.VirtualMemorySize) - ($then.VirtualMemorySize) )
}

write $array_out

 
