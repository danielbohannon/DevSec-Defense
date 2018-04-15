#This scripts compares the agents that are installed in two zones and
#gives the agents that are not common.

#Usage:
#Compare-Agents.ps1 -server1 RMSServer1.contoso.com -server2 RMSServer2.contoso.com -output c:\\Temp.txt
#RMSServer1 is the one whose agents are to be moved.
param([string] $Server1,$Server2,$output)

Function Mainone
{
   write-host $Server1
   write-host $Server2
   $Temp1 = $Server1
   $Temp2 = $Server2
   $outfilepath = $output
   New-Managementgroupconnection $Temp1
   set-location monitoring:\\$Temp1
   $AllServer1Agents = get-agent
   $RMSServer1 = get-RootManagementServer
   write-host "Got all the agents for the first group"
   $RMS1name = $RMSServer1.Computername 
   $data1 = "All the agents on " + $RMS1name
  

   New-Managementgroupconnection $Temp2
   set-location monitoring:\\$Temp2
   $AllServer2Agents = get-agent
   $RMSServer2 = get-RootManagementServer
   write-host "Got all the agents for the second group"
   #Write-data $RMSServer.ManagementGroup.name
   $RMS2name = $RMSServer2.Computername
   $data2 = "All the agents on " + $RMS2name
   #write-data $data2
   #foreach($Agent in  $AllServer2Agents) { write-data $Agent.computername}
   write-host "Calling the function to compare Agents"
   CheckAgent $AllServer1Agents $AllServer2Agents $RMS1name $RMS2name

}


Function CheckAgent($AllServer1Agents,$AllServer2Agents,$RMS1name,$RMS2name)
{
   
   write-host "Calling function to get all agents in an array"
   Get-Agentnames   $AllServer1Agents $AllServer2Agents $RMS1name $RMS2name
   
}


Function Get-Agentnames($AllServer1Agents,$AllServer2Agents,$RMS1name,$RMS2name)
{
   $Server1Agent = @() 
   $Server2Agent = @()
 
 foreach($A in $AllServer1Agents)
  {
   $Server1Agent = $Server1Agent + $A.Computername
  }
foreach($B in $AllServer2Agents)
  {
   $Server2Agent = $Server2Agent + $B.Computername
  }
   
Compare-theAgents $Server1Agent $Server2Agent
 
}

function Compare-theAgents($Server1Agent,$Server2Agent)
{
   $FoundAgent = @()
   $NotFoundAgent = @()
   
for($i=0; $i -lt $Server1Agent.count; $i++)
    {
     $Temp1 = $Server1Agent[$i]
     $Data = "Comparing element " + $Server1Agent[$i]
     write-host $Data
     for($j=0; $j -lt $Server2Agent.count; $j++)
         {
           $Temp2 = $Server2Agent[$j]
           #write-host $Temp2
           if($Temp1 -match $Temp2) 
           {
              $FoundAgent = $FoundAgent + $Temp1 
              $Server1Agent[$i] = "Present"
           }                   
         }
    }
for($k=0; $k -lt $Server1Agent.count; $k++)
    {
      
        if($Server1Agent[$k] -notmatch "Present")
           {
                 $NotfoundAgent = $NotFoundAgent + $Server1Agent[$k]
           }
    }

  write-data "These are the agents that are found common"
 for($k=0;$k -lt $FoundAgent.count;$k++){write-data $FoundAgent[$k]}
 write-data "These are the agents that are not found"
 for($l=0;$l -lt $NotFoundAgent.count;$l++){write-data $NotFoundAgent[$l]}
}

function write-data($Writedata)
{

out-file -filepath $outfilepath -inputobject $Writedata -append -encoding ASCII

}
Mainone
