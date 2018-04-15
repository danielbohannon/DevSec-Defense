## Because of Split-Path, I get the "Framework" folder path (one level above the versioned folders)
$rtr = Split-Path $([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())

## Then I loop through them in ascending (numerical, but really ascii) order
## each time I find installutil or mdbuild, I update the alias to point at the newer version
foreach($rtd in get-childitem $rtr -filt v* | sort Name) {
   if( Test-Path (join-path $rtd.FullName installutil.exe) ) {
      set-alias installutil (resolve-path (join-path $rtd.FullName installutil.exe))
   }
   if( Test-Path (join-path $rtd.FullName msbuild.exe) ) {
      set-alias msbuild (resolve-path (join-path $rtd.FullName msbuild.exe))
   }
}

