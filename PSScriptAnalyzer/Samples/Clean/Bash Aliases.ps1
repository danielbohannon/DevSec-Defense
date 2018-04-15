## Aliases Module, Bash-style aliases with functions
function alias {
   # pull together all the args and then split on =
   $alias,$cmd = [string]::join(" ",$args).split("=",2) | % { $_.trim()}

   if($Host.Version.Major -ge 2) {
      $cmd = Resolve-Aliases $cmd
   }
   New-Item -Path function: -Name "Global:Alias$Alias" -Options "AllScope" -Value @"
Invoke-Expression '$cmd `$args'
###ALIAS###
"@

   Set-Alias -Name $Alias -Value "Alias$Alias" -Description "A UNIX-style alias using functions" -Option "AllScope" -scope Global -passThru
}

function unalias([string]$Alias,[switch]$Force){ 
   if( (Get-Alias $Alias).Description -eq "A UNIX-style alias using functions" ) {
      Remove-Item "function:Alias$Alias" -Force:$Force
      Remove-Item "alias:$alias" -Force:$Force
      if($?) {
         "Removed alias '$Alias' and accompanying function"
      }
   } else {
      Remove-Item "alias:$alias" -Force:$Force
      if($?) {
         "Removed alias '$Alias'"
      }
   }
}

function Get-AliasFor([string]$CommandName) {
  ls Alias: | ?{ $_.Definition -match $CommandName }
}

# Export the public functions using Export-ModuleMember cmdlet
Export-ModuleMember alias,unalias,Get-AliasFor
