Add-SharePointLibraryFile
{
	param
	(
		[System.IO.FileInfo] $File, 
		[System.Uri] $DocumentLibraryUrl = $(throw "Parameter -DocumentLibraryUrl [System.Uri] is required.")
	)

	Begin
	{ }
	
	Process
	{
		if($_)
		{
			$File = [System.IO.FileInfo] $_
		}
		
		if (!$File.Exists)
		{
			Write-Error ($File.ToString() + " does not exist.")
			return $null
		}
		
		trap
		{
			Write-Error $_.Exception.Message
			break
		}
	
		[string]$webPath = $DocumentLibraryUrl
		if (-not $webPath.EndsWith("/")) {
			$webPath += "/";
		}
		$webPath += $File.Name
	
		#Create a PUT Web request to upload the file.
		$request = [System.Net.WebRequest]::Create($webPath)
	
		#Set credentials of the current security context
		$request.Credentials = [System.Net.CredentialCache]::DefaultCredentials
		$request.Method = "PUT";
	
		# Create buffer to transfer file		
		$fileBuffer = New-Object byte[] 1024
	
		# Write the contents of the local file to the request stream.
		$stream = $request.GetRequestStream()
		
		$fsWorkbook = $file.OpenRead()
		
		#Get the start point
		$startBuffer = $fsWorkbook.Read($fileBuffer, 0, $fileBuffer.Length);
		
		for ($i = $startBuffer; $i -gt 0; $i = $fsWorkbook.Read($fileBuffer, 0, $fileBuffer.Length))
		{
			$stream.Write($fileBuffer, 0, $i);
		}
		
		$stream.Close()
	
		# Perform the PUT request
		$response = $request.GetResponse();
	
		#Close response
		$response.Close();
	}
	
	End
	{ }
}


$url = "http://sharepoint/sites/andy/files"

Get-Item 'C:\\Documents and Settings\\andy\\Desktop\\doc.pdf' | Add-SharePointLibraryFile -DocumentLibraryUrl $url

