#load boots#
Import-Module Powerboots


function Export-NamedControl {
	[CmdletBinding()]
	param(
	   [Parameter(ValueFromPipeline=$true, Position=1, Mandatory=$true)]
	   $Root = $BootsWindow
	)
	process {
	   Invoke-BootsWindow $Root { 
		  $control = $BootsWindow 
		  while($control) {
			 $control = $control | ForEach-Object {
				$Element = $_
				if(!$Element) { return }
	   
				Write-Verbose "This $($Element.GetType().Name) is $Element"
	  
				if($Element.Name) {
				   Write-Verbose "Defining $($Element.Name) = $Element"
				   Set-Variable "$($Element.Name)" $Element -Scope 2
				}
				## Return all the child controls ...
				@($Element.Children) + @($Element.Child) + @($Element.Content) + 
				@($Element.Items) + @($Element.Inlines) + @($Element.Blocks)
			 }
		  }
	   }
	}
}

function ConvertFrom-Hashtable {
PARAM([HashTable]$hashtable,[switch]$combine)
BEGIN { $output = New-Object PSObject }
PROCESS {
if($_) { 
   $hashtable = $_;
   if(!$combine) {
      $output = New-Object PSObject
   }
}
   $hashtable.GetEnumerator() | 
      ForEach-Object { Add-Member -inputObject $output `
	  	-memberType NoteProperty -name $_.Name -value $_.Value }
   $output
}
}

#--- Boots ---#
$window = New-BootsWindow {} -FileTemplate "[your_path to xaml_file.xaml]" -async -Passthru -On_Loaded {
    Export-NamedControl -Root $Args[0]
	$data = @{ 
		DeviceGroup = "Samsung" 
		Device = "SGH-A887" 
		Platform = "J2ME" 
	}, @{ 
		DeviceGroup = "Motorola"
		Device = "V3i"
		Platform = "J2ME"
	}   | ConvertFrom-Hashtable
	
	$HadesDevices.ItemsSource = $data
}
