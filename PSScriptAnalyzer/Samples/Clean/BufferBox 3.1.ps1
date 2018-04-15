####################################################################################################
## This script is just a demonstration of some of the things you can do with the buffer
## in the default PowerShell host... it serves as a reminder of how much work remains on
## PoshConsole, and as an inspiration to anyone who is thinking about trying to create
## "interactive" PowerShell applications.
##
## Try Test-DisplayBox and then Test-BufferBox (note it has tab completion and everything).
####################################################################################################
$global:BoxChars = new-object PSObject -Property @{
   'HorizontalDouble'            = ([char]9552).ToString()
   'VerticalDouble'              = ([char]9553).ToString()
   'TopLeftDouble'               = ([char]9556).ToString()
   'TopRightDouble'              = ([char]9559).ToString()
   'BottomLeftDouble'            = ([char]9562).ToString()
   'BottomRightDouble'           = ([char]9565).ToString()
   'HorizontalDoubleSingleDown'  = ([char]9572).ToString()
   'HorizontalDoubleSingleUp'    = ([char]9575).ToString()
   'Horizontal'                  = ([char]9472).ToString()
   'Vertical'                    = ([char]9474).ToString()
   'TopLeft'                     = ([char]9484).ToString()
   'TopRight'                    = ([char]9488).ToString()
   'BottomLeft'                  = ([char]9492).ToString()
   'BottomRight'                 = ([char]9496).ToString()
   'Cross'                       = ([char]9532).ToString()
   'VerticalDoubleRightSingle'   = ([char]9567).ToString()
   'VerticalDoubleLeftSingle'    = ([char]9570).ToString()
}
$global:RectType = "system.management.automation.host.rectangle"

function Reset-Buffer {
param(
   $Position = $Host.UI.RawUI.WindowPosition,
   [int]$Height = $Host.UI.RawUI.WindowSize.Height,
   [int]$Width = $Host.UI.RawUI.WindowSize.Width,
   # Note: all edges are padded by 1 for the box edges, but we also pad each side by this ammount:
   [int]$Padding = 1,
   $ForegroundColor = $Host.UI.RawUI.ForegroundColor,
   $BackgroundColor = $Host.UI.RawUI.BackgroundColor,
   $BorderColor     = "Yellow",
   [switch]$NoBorder,
   [switch]$ShowInput,
   [string]$Title = ""
)

$global:BufferHeight          = $Height
$global:BufferWidth           = $Width
$global:BufferPadding         = $Padding
$global:BufferForegroundColor = $ForegroundColor 
$global:BufferBackgroundColor = $BackgroundColor 
$global:BufferBorderColor     = $BorderColor     

   if($NoBorder) {
      $global:BufferBoxSides = 0
   } else {
      $global:BufferBoxSides = 2
   }
   if($ShowInput) {
      $global:BufferHeight -= 2
   }

   $Host.UI.RawUI.SetBufferContents($Position,(New-BufferBox $BufferHeight $BufferWidth -Title:$Title -NoBorder:$NoBorder -ShowInput:$ShowInput -Background $BufferBackgroundColor -Border $BufferBorderColor))
  
   
   $global:BufferPosition = $Position   
   $global:BufferPosition.X += $global:BufferPadding + ($global:BufferBoxSides/2)
   # this gets set to the BOTTOM line, because I assume text will flow in from the bottom.
   $global:BufferPosition.Y += $global:BufferHeight - 2
   # and this goes below that ...
   $global:BufferPromptPosition = $BufferPosition
   $global:BufferPromptPosition.Y += 2
   $global:BufferPromptPosition.X += 2 - $global:BufferPadding # Prompt = "> "
}

function New-BufferBox {
param(
   [int]$Height = $global:BufferHeight, 
   [int]$Width = $global:BufferWidth,
   $Title = "",
   [switch]$NoBorder,
   [switch]$ShowInput,
   $BackgroundColor = $global:BufferBackgroundColor,
   $BorderColor = $global:BufferBorderColor 
)
   $Width = $Width - $global:BufferBoxSides
   
   $LineTop =( $global:BoxChars.HorizontalDouble * 2) + $Title `
            + $($global:BoxChars.HorizontalDouble * ($Width - ($Title.Length+2)))
   
   $LineField = ' ' * $Width
   $LineBottom = $global:BoxChars.HorizontalDouble * $Width
   $LineSeparator = $global:BoxChars.Horizontal * $Width
   $LinePrompt = '> ' + ' ' * ($Width-2) # Prompt = "> "
   
   if(!$NoBorder) {
      $LineField = $global:BoxChars.VerticalDouble + $LineField + $global:BoxChars.VerticalDouble
      $LinePrompt = $global:BoxChars.VerticalDouble + $LinePrompt + $global:BoxChars.VerticalDouble
      $LineBottom = $global:BoxChars.BottomLeftDouble + $LineBottom + $global:BoxChars.BottomRightDouble
      $LineTop = $global:BoxChars.TopLeftDouble + $LineTop + $global:BoxChars.TopRightDouble
      $LineSeparator = $global:BoxChars.VerticalDoubleRightSingle + $LineSeparator + $global:BoxChars.VerticalDoubleLeftSingle
   }

   if($ShowInput) {
      $box = &{$LineTop;1..($Height - 2) |% {$LineField};$LineSeparator;$LinePrompt;$LineBottom}
   } else {
      $box = &{$LineTop;1..($Height - 2) |% {$LineField};$LineBottom}
   }
   $boxBuffer = $Host.UI.RawUI.NewBufferCellArray($box,$BorderColor,$BackgroundColor)
   return ,$boxBuffer
}

function Move-Buffer {
param(
   $Position = $global:BufferPosition,
   [int]$Left = $($global:BufferBoxSides/2),
   [int]$Top = (2 - $global:BufferHeight),
   [int]$Width = $global:BufferWidth - $global:BufferBoxSides,
   [int]$Height = $global:BufferHeight,
   [int]$Offset = -1
)
   $Position.X += $Left
   $Position.Y += $Top
   $Rect = New-Object $RectType $Position.X, $Position.Y, ($Position.X + $width), ($Position.Y + $height -1)
   $Position.Y += $OffSet
   $Host.UI.RawUI.ScrollBufferContents($Rect, $Position, $Rect, (new-object System.Management.Automation.Host.BufferCell(' ',$global:BufferForegroundColor,$global:BufferBackgroundColor,'complete')))
}

function Out-Buffer {
param(
   [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
   $Message, 
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   $ForegroundColor = $global:BufferForegroundColor, 
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   $BackgroundColor = $global:BufferBackgroundColor, 
   
   [switch]$NoScroll,
   
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   $Position = $global:BufferPosition,
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   [int]$Left = 0,
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   [int]$Top    = $(3 - $global:BufferHeight),  # Box Edge + New Lines
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   [int]$Width  = ($global:BufferWidth - $global:BufferBoxSides), # Box Edge
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   [int]$Height = ($global:BufferHeight - $global:BufferBoxSides), # Box Edge
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   [int]$Offset = $( 0 - ($Message.Split("`n").Count))
)
process {
   $lineCount = $Message.Split("`n").Count

   $Width = $Width - ($global:BufferPadding * 2)
   if(!$NoScroll){ Move-Buffer $Position $Left $Top $Width $Height $Offset }
   
   $MessageBuffer = New-Object "System.Management.Automation.Host.BufferCell[,]" $lineCount, $width
   
   $index = 0
   foreach( $line in $Message.Split("`n") ) {
      $Buffer = $Host.UI.RawUI.NewBufferCellArray( @($line.Trim("`r").PadRight($Width)), $ForegroundColor, $BackgroundColor )
      for($i = 0; $i -lt $width; $i++) {
         $MessageBuffer[$index,$i] = $Buffer[0,$i]
      }
      $index++
   }
   
   $Y = $global:BufferPosition.Y
   $global:BufferPosition.Y -= $lineCount - 1
   $Host.UI.RawUI.SetBufferContents($global:BufferPosition,$MessageBuffer)
   $global:BufferPosition.Y = $Y
}
}

function Set-BufferInputLine {
param([String]$Line = "")
   $PromptText = $line.PadRight(($global:BufferWidth - $line.Length - 3)) # Prompt = "> "
   
   $CursorPosition = $BufferPromptPosition
   $CursorPosition.X += $line.Length
   
   $Prompt = $Host.UI.RawUI.NewBufferCellArray( @($PromptText),$global:BufferForegroundColor, $global:BufferBackgroundColor)
   $Host.UI.RawUI.SetBufferContents( $BufferPromptPosition, $prompt )
   $Host.UI.RawUI.CursorPosition = $CursorPosition
}

function Test-DisplayBox {
   $Position = $Host.UI.RawUI.WindowPosition
   $Position.X += 10
   $Position.Y += 3

   Reset-Buffer $Position 20 66 3 -ForegroundColor 'Gray' -BackgroundColor 'Black' -BorderColor 'Green'
   Out-Buffer 'Greetings!' 'Yellow' 'black'
   sleep -m 600
   Out-Buffer '' 'Gray' 'black'
   sleep -m 600
   Out-Buffer '- - - Thank you for running this simple demo script! - - -' 'Green' 'black'
   sleep -m 600
   Out-Buffer '' 'Gray' 'black'
   sleep -m 600
   Out-Buffer 'We are demonstrating how the scroll buffer works: you can
add more than one line at a time, but you don''t really 
need to, since they add almost as fast one at a time.' 'white' 'black'
   sleep -m 3000
   Out-Buffer '' 'Gray' 'black'
   Out-Buffer 'That is, as long as you don''t have any delay, you can just' 'white' 'black'
   Out-Buffer 'write out as many lines as you like, one-at-a-time, like' 'white' 'black'
   Out-Buffer 'this, and there is really no downside to doing that.' 'white' 'black'
   sleep -m 3000
   Out-Buffer '' 'Gray' 'black'
   Out-Buffer 'Right? '.PadRight(58,"-") 'Red' 'black'   
   Out-Buffer '' 'Gray' 'black'
   sleep -m 600
   Out-Buffer 'It''s clearly not as slick to just pop in multiple lines' 'white' 'black'
   sleep -m 1200
   Out-Buffer 'with absolutely no scroll delay, and it makes it a little ' 'white' 'black'
   sleep -m 1200
   Out-Buffer 'hard to tell what you have read already, but that''s ok.' 'white' 'black'
   sleep -m 1200
   Out-Buffer '' 'Gray' 'black'
   sleep -m 600
   Out-Buffer 'If you delay between paragraphs.' 'Red' 'black'   
   sleep -m 600
   Out-Buffer '' 'Gray' 'black'
   sleep -m 600
   Out-Buffer 'But: don''t scroll off-screen faster than I can read!' 'Yellow' 'black'   
   sleep -m 600
   Out-Buffer '' 'Gray' 'black'
}

## Test-BufferBox 3.1 - Now with Tab completion
####################################################################################################
## Imagine it's a chat window: you can type, but the whole time, the ongoing conversation in the 
## chat room you have joined is going on in the background.
##
## NOTE: because this is a "chat" demo, we treat your input as text, and to execute script in-line 
## you have to enclose it inside $() braces.
####################################################################################################
function Test-BufferBox {
param( $title = "PowerShell Interactive Buffer Demo" )

Reset-Buffer -ShowInput -Title $Title

###################################################################################################
##### We only need this for the purposes of the demo...
##### In a real script you would, presumably, be getting stuff from somewhere else to display
   $noise = $MyInvocation.MyCommand.Definition -split "`n"
   $index = 0; 
   $random = New-Object "Random"
[regex]$chunker = @'
[^ \\"']+|([\\"'])[^\\\\1]*?\\\\1[^ \\"']*|([\\"'])[^\\\\1]*$| $
'@
##### Printing a "How to Exit" message
Out-Buffer "  " -Fore DarkGray -Back Cyan
Out-Buffer "     This is just a demo. " -Fore Black -Back Cyan
Out-Buffer "     We will stream in the source code of this script ... " -Fore Black -Back Cyan
Out-Buffer "     And you can type at the bottom while it's running. " -Fore Black -Back Cyan
Out-Buffer "     Imagine this as an n-way chat application like IRC, except that " -Fore Black -Back Cyan
Out-Buffer "  FOR THIS PERFORMANCE ONLY: " -Fore Black -Back Cyan
Out-Buffer "         The part of your chatting friends is played by my source code. " -Fore DarkGray -Back Cyan
Out-Buffer "  " -Fore DarkGray -Back Cyan
Out-Buffer "     Press ESC to exit, or enter 'exit' and hit Enter" -Fore Black -Back Cyan
Out-Buffer "  " -Fore DarkGray -Back Cyan
##### Setting the prompt
Set-BufferInputLine
##### And initializing our two variables ...
$line=""
$exit = $false
while(!$exit){
   while(!$exit -and $Host.UI.RawUI.KeyAvailable) { 
      $char = $Host.UI.RawUI.ReadKey("IncludeKeyUp,IncludeKeyDown,NoEcho"); 
      # we don't want the key up events, but we do want to get rid of them
      if($char.KeyDown) {
      switch([int]$char.Character) {
         13 { # Enter
               if($line.Trim() -eq "exit") { $exit = $true; break; }
###################################################################################################
###################################################################################################
############# WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING #############
############# This executes the user input!                                           #############
############# Don't use this on, say, content you got from a web page or chat room    #############
            iex "Out-Buffer `"$line`" -Fore Red";                                     #############
###################################################################################################
###################################################################################################
            $line = "";
            Set-BufferInputLine
            break;
         }
         27 { # Esc
            $exit = $true; break;
         }
         9 { # Tab
            if($line.Length -gt 0) {
               [Array]$words = $chunker.Matches($line)
               if($words.Count -ge 1) {
                  Out-Buffer ($Words | Out-String) -Fore Black -Back White
                  $lastWord = $words[$($words.Count-1)].Value
                  $trim = $lastWord.TrimEnd("`r","`n")
                  ## This may return more than one ... in which case subsequent tabs should iterate through them
                  ## But for demo purposes, this is more than enough work...
                  $replacement = TabExpansion -Line $line -LastWord ($lastWord.Trim() -replace '"')
                  Out-Buffer ($replacement | Out-String) -Fore Black -Back White
                  $line = $line.SubString(0, $line.Length - $lastWord.Length) + @($replacement)[0]
                  Set-BufferInputLine $line
               }
            }         
            break;
         }
            8 { # Backspace
            if($line.Length -gt 0) {
               $line = $line.SubString(0,$($line.Length-1))
            }
            # $pos = $Host.UI.RawUI.CursorPosition
            Set-BufferInputLine $line
            break;
         }         
         0 { 
            # Not actually a key
            # Out-Buffer $($Char | Out-String)
            break;
         }
         default {
            $line += $char.Character
            Set-BufferInputLine $line
         }
      }
      }
   }
   # Simulate doing useful things 25% of the time
   if($random.NextDouble() -gt 0.75) {
      $noise[($index)..($index++)] | Out-Buffer
      if($index -ge $noise.Length){$index = 0}
   }
   sleep -milli 100
}
$CursorPosition = $BufferPromptPosition
$CursorPosition.Y += 2
$CursorPosition.X = 0
$Host.UI.RawUI.CursorPosition = $CursorPosition
}
