## Add-UniqueEndings
## Takes an array of strings and forces them to be unique by adding _<number> tails to duplicates.
####################################################################################################
## Usage:
##   $$: (Add-UniqueEndings "one","two","three","one","two","one","one_5").ToString()
##   one, two, three, one_1, two_1, one_2, one_3
##
##   $$: ("one","two","three","one","two","one","one_5" | Add-UniqueEndings).ToString()
##   one, two, three, one_1, two_1, one_2, one_3
####################################################################################################
## History:
## v1   - adds tails _ until the string is unique
## v2   - adds number tails _1 instead
## v2.5 - works with the array passed as an argument (default is on the pipeline)
####################################################################################################
function Add-UniqueEndings {
   BEGIN {
      if($args.Count) { 
         $args[0] | Add-UniqueEndings
      } else {
         $uniques  = @{}
         $collect  = @()
      }
   }
   PROCESS {
      if($_){
         $item = "$_" -replace "(.*)_\\d+",'$1'
         $collect += $item
         $uniques.$item += 1
      }
   }  
   END {
      if(!$args.Count -and $collect.Count) { 
         [Array]::Reverse($collect)
         $collect = $collect | % { if($uniques.$_-- -eq 1){ $_ } else { "$_$('_')$($uniques.$_)" } }
         [Array]::Reverse($collect)
         $collect
      }
   }
}


