function ConvertTo-RelativeTimeString {
#.Synopsis 
#  Calculates a relative text version of a duration
#.Description
#  Generates a string approximation of a timespan, like "x minutes" or "x days." Note this method does not add "about" to the front, nor "ago" to the end unless you pass them in.
#.Parameter Span
#  A TimeSpan to convert to a string
#.Parameter Before
#  A DateTime representing the start of a timespan.
#.Parameter After
#  A DateTime representing the end of a timespan.
#.Parameter Prefix
#  The prefix string, pass "about" to render: "about 4 minutes"
#.Parameter Postfix
#  The postfix string, like "ago" to render: "about 4 minutes ago"
[CmdletBinding(DefaultParameterSetName="TwoDates")]
PARAM(
   [Parameter(ParameterSetName="TimeSpan",Mandatory=$true)]
   [TimeSpan]$span
,
   [Parameter(ParameterSetName="TwoDates",Mandatory=$true,ValueFromPipeline=$true)]
   [Alias("DateCreated")]
   [DateTime]$before
,
   [Parameter(ParameterSetName="TwoDates", Mandatory=$true, Position=0)]
   [DateTime]$after
,
   [Parameter(Position=1)]
   [String]$prefix = ""
,
   [Parameter(Position=2)]
   [String]$postfix = ""
 
)
PROCESS {
   if($PSCmdlet.ParameterSetName -eq "TwoDates") {
      $span = $after - $before
   }
   
   "$(
   switch($span.TotalSeconds) {
      {$_ -le 1}      { "$prefix a second $postfix "; break }     
      {$_ -le 60}     { "$prefix $($span.Seconds) seconds $postfix "; break }
      {$_ -le 120}    { "$prefix a minute $postfix "; break }
      {$_ -le 2700}   { "$prefix $($span.Minutes) minutes $postfix "; break } # 45 minutes or less
      {$_ -le 5400}   { "$prefix an hour $postfix "; break } # 45 minutes to 1.5 hours 
      {$_ -le 86400}  { "$prefix $($span.Hours) hours $postfix "; break } # less than a day
      {$_ -le 172800} { "$prefix 1 day $postfix "; break } # less than two days
      default         { "$prefix $($span.Days) days $postfix "; break } 
   }
   )".Trim()
}
}

