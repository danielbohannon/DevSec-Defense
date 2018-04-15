#region setup AS function
function new-selectexpression
{
if ($args.count -eq 1) { $theargs = $args[0] } else {$theargs= $args }
if ($theargs.count -gt 1)
{
for($loop=0;$loop -lt ($theargs.count-1);$loop+=2)
 { 
  @{Name=$theargs[$loop];Expression=$theargs[$loop+1]} 
 }
}
if (!($theargs.count % 2) -eq 0) {@{Name=$input[$input.count-1];Expression= invoke-Expression "{}" } }
}
set-Alias as  new-selectexpression
#endregion
#Examples
#Select (as theprocess ,name , 
#            "CPU" , {$_.privatememorysize/ 1KB} , 
#			"memory KB" , {$_.privatememorysize/ 1KB} , 
#			"peak KB",  {$_.peakworkingset /1KB} ) -first 2 
