Param([Parameter(ValueFromPipeline=$true)]$object,[switch]$AsString,[switch]$jagged)
BEGIN { $headers = @() }
PROCESS {
   if(!$headers -or $jagged) {
      $headers = $object | get-member -type Properties | select -expand name
   }
   $output = @{}
   if($AsString) {
      foreach($col in $headers) {
         $output.$col = $object.$col | out-string -Width 9999 | % { $_.Trim() }
      }
   } else {
      foreach($col in $headers) {
         $output.$col = $object.$col
      }
   }
   $output
}

