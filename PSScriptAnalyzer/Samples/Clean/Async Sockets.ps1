if (-not ("CallbackEventBridge" -as [type])) {
   Add-Type @"
      using System;
      
      public sealed class CallbackEventBridge
      {
          public event AsyncCallback CallbackComplete = delegate { };

          private CallbackEventBridge() {}

          private void CallbackInternal(IAsyncResult result)
          {
              CallbackComplete(result);
          }

          public AsyncCallback Callback
          {
              get { return new AsyncCallback(CallbackInternal); }
          }

          public static CallbackEventBridge Create()
          {
              return new CallbackEventBridge();
          }
      }
"@ }


function Open-Socket {
#.Synopsis
#  Open an Internet Socket
#.Parameter Server
#  The name of the server to connect to
#.Parameter Port
#  The port to connect to on the remote server
#.Parameter SocketType
#  The type of socket to open.
#  Valid values include Stream, Dgram, Raw, Seqpacket, etc.
#
#  Default value                Stream
#.Parameter ProtocolType
#  The protocol to use over the socket.
#  Valid values include Tcp, Udp, Icmp, Ipx, etc.
#
#  Default value                Tcp
#.Example
#  $socket = Open-Socket google.com 80
param(
   [Parameter(Mandatory=$true, Position=0)]
   [Alias("Host")]
	[string]$Server
, 
   [Parameter(Mandatory=$true, Position=1)]
   [int]$Port
, 
   [Parameter()]
   [System.Net.Sockets.SocketType]$SocketType = "Stream"
,
   [Parameter()]
   [System.Net.Sockets.ProtocolType]$ProtocolType = "Tcp"
)
end {
	$socket = new-object System.Net.Sockets.Socket "InterNetwork", $SocketType, $Protocol
	$socket.Connect($Server, $Port)
   Write-Output $socket
}
}


function Expect-String {
#.Synopsis
#  Read data from an open socket asynchronously (using BeginRead/EndRead).
#.Description
#  Reads data from an open socket in an async manner, allowing the script to continue and even to cancel reading.
#  Provides an advanced system for reading up to an expected string with buffering and regex matching.
#.Parameter Socket
#  The socket to read from
#.Parameter Expect
#  One or more patterns to match on (regex syntax supported)
#  Note: a null value will match all remaining output from the socket
#.Parameter SendFirst
#  Text to send through the socket before reading. For example, a telnet command or http GET request.
#.Parameter BufferLength
#  The size buffer to use when reading from the socket
#
#  Default value                100
#.Parameter OutputBuffer
#  A List[String] for the output. Defaults to an empty collection, but you can pass in an existing collection to append to.
#  This is primarily for use when piping the output of Expect-String back to Expect-String to build up multiple results.
#.Parameter Wait
#  The number of seconds to wait for the socket reads to finish.
#.Notes
#  Expect-String doesn't close the socket, in case you need to call Expect-String on it again
#.Example
#  $socket = Open-Socket www.xerox.com 80
#  C:\\PS>$State = Expect-String -Socket $socket -Send "GET / HTTP/1.1`r`nHost: www.xerox.com`r`n`r`n" -Wait 30 -Expect ".*(?=<)",".*(?=<body>)","</body>",$null
#  C:\\PS>$socket.Close()
#  C:\\PS>Write-Host "Headers:" $State.Output[0]
#  C:\\PS>Write-Host "Body:" $State.Output[2]
#
#  Description
#  -----------
#  This calls Expect-String with four expectations, which means there will be four items in $State.Output if they all match.  The 3rd item (index 2) will show the entire body of the Xerox homepage.  Notice that the first two are using regular expression positive lookaheads (the parenthesis and ?= enclosing some text) to match up to but not including the tags.  The four expectations specified result in the http headers, the html up to (but not including) the body tag, the whole body, and anything else that comes after the body (</html>) being in Output, because putting $null as the last expectation copies all remaining data until the end of the stream. We then close the socket.
#
#  NOTE: Using -Wait causes Expect-String not to return until either all expectations are met, we reach the end of the data, or we timeout. Otherwise, Expect-String returns immediately, but you have to manually check $State.Complete
#
#.Example
#  $State = Open-Socket localhost 80 | 
#           Expect-String -Send "GET /xsm57/ui/home.aspx HTTP/1.1`r`nHost: localhost`r`n`r`n"
#  while(!$State.Complete) { write-host $State.Output.Length "characters so far." }  
#
#  Description
#  -----------
#  Without the -Wait parameter, this will return instantly, but the data may not have started arriving yet.  Note that on a fast server, once the data starts arriving, it arrives so fast that the Write-Host line may never write anything but zeros, and since we're not -Expecting anything, it should just return everything as a single string in $State.Output

param(
   [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
   [System.Net.Sockets.Socket]$Socket
,
   [Parameter(Position=0,ValueFromPipelineByPropertyName=$true)]
   [String[]]$Expect = @()
,
   [String]$SendFirst
,
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   [Int]$BufferLength = 100
,
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   [Alias("Output")]
   [System.Collections.Generic.List[String]]$OutputBuffer = $(New-Object System.Collections.Generic.List[String])
,
   [double]$Wait
)
begin {
   if($SendFirst) {
      $Socket.Send(([char[]]$SendFirst)) | Out-Null
   }
   $Expecting = $Expect -as [bool]
   
   New-Object PSObject @{
      Bridge = [CallbackEventBridge]::create()
      Buffer = New-Object System.Byte[] $BufferLength
      BufferLength = $BufferLength
      Received = New-Object System.Text.StringBuilder
      Output = $OutputBuffer
      Socket = $Socket
      Complete = $false
      Expecting = $Expect
   } | Tee-Object -Variable State
}

process {
   Trap [System.ObjectDisposedException] {
      Write-Warning "The socket was forcibly closed"
   }
   
  
   Register-ObjectEvent -input $State.Bridge -EventName CallbackComplete -action {
		param($AsyncResult) 
      
      Trap [System.ObjectDisposedException] {
         Write-Warning "The socket was forcibly closed"
         $as.Complete = "ERROR: The socket was forcibly closed"
      }
      
      $as = $AsyncResult.AsyncState
      
      $read = $as.Socket.EndReceive( $AsyncResult )
      Write-Verbose "Reading $read"
      if($read -gt 0) {
         $as.Received.Append( ([System.Text.Encoding]::ASCII.GetString($as.Buffer, 0, $read)) ) | Out-Null
      }
      
      ## This is the "Expect" logic which aborts reading when we get what we wanted ...
      if(($as.Expecting.Count -gt $as.Output.Count) -and $as.Received.Length -gt $as.Expecting[$as.Output.Count].Length -and $as.Expecting[$as.Output.Count]) {
         $Expecting = $as.Expecting[$as.Output.Count]
         Write-Verbose "Expecting $Expecting"
         # Speeds up matching if the results are large
         $StartIndex = [Math]::Max(($as.Received.Length - [Math]::Max(($as.BufferLength * 2), $Expecting.Length)), 0)
         $Length = $as.Received.Length - $StartIndex
         
         $match = [regex]::Match( $as.Received.ToString( $StartIndex, $Length ), $Expecting )
         if( $match.Success ) {
            $match | Out-String | Write-Verbose 
            $matchEnd = $StartIndex + $match.Index + $match.Length
            $as.Output += $as.Received.ToString(0, $matchEnd)
            $as.Received = New-Object System.Text.StringBuilder $as.Received.ToString($matchEnd, $as.Received.Length - $matchEnd)
            ## If there's nothing left to expect, then ... don't
            if($as.Expecting.Count -eq $as.Output.Count) {
               $as.Complete = "Success: All matches found"
               $read = 0 # Finish reading for now ...
            }
         }
      }
      
      ## It is more correct to keep trying until we get 0 bytes, but some servers never respond when they have 0 to send.
      # if($read -gt 0) { 
      if($read -eq $as.BufferLength) {
         # Keep reading ...
         $as.Socket.BeginReceive( $as.Buffer, 0, $as.BufferLength, "None", $as.Bridge.Callback, $as ) | Out-Null
      } else {
         # If we weren't "expecting" or if the last expectation is null (or empty)
         # put everything we've received into the output buffer
         if($as.Expecting.Count -eq 0 -or $as.Expecting[-1].Length -eq 0) {
            $as.Output += $as.Received.ToString()
            $as.Received = New-Object System.Text.StringBuilder
         }
         $as.Complete  = $true
      }
	} | Out-Null

   Write-Verbose "Begin Receiving"
   $State.Socket.BeginReceive( $State.Buffer, 0, $State.BufferLength, "None", $State.Bridge.Callback, $State ) | Out-Null # | Select * -Expand AsyncState | Format-List | Out-String | Write-Verbose
}
end {
   if($Wait) {
      while($Wait -gt 0 -and !$State.Complete) {
         Sleep -milli 500
         $Wait -= 0.5
         Write-Progress "Waiting to Receive" "Still Expecting Output $Expect" -SecondsRemaining $Wait
      }
   }
}
}



