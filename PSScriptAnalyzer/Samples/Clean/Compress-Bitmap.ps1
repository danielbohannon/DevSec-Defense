function Compress-Bitmap {
PARAM(
   [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
   [IO.FileInfo]$SourceFile
,
   [Parameter(Mandatory=$true, Position=1)]
   [String]$DestinationFile
,   
   [Parameter(Mandatory=$false)]
   [Int]$Width
,  [Parameter(Mandatory=$false)]
   [Int]$Height   
,  [Parameter(Mandatory=$false)]
   [Int]$MaxFilesize
,  [Parameter(Mandatory=$false)]
   [Int]$Quality = 100
)
BEGIN { if($SourceFile) { $SourceFile = Get-ChildItem $SourceFile } }
PROCESS {
   # Work our way down until we get a small enough file (this might be slow)
   [string]$intermediate = [IO.path]::GetRandomFileName() + ".jpeg"
   $bitmap = Import-Bitmap $SourceFile
   
   if($Width -and $Height) {
      $bitmap = Resize-Bitmap -Bitmap $bitmap -Width $Width -Height $Height
   } else { # work around another bug in Export-Bitmap
      $bitmap = Resize-Bitmap -Bitmap $bitmap -Percent 100
   }
   
   do { 
      Export-Bitmap -Bitmap $bitmap -Path $intermediate -Quality ($Quality--)
   } while( $MaxFilesize -and ((Get-ChildItem $intermediate).Length -gt $MaxFilesize))
   Write-Host "Output Quality: $($Quality + 1)%" -Foreground Yellow
   Move-Item $intermediate $DestinationFile -Force -Passthru
}
}

