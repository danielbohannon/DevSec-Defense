function Copy-File {
#.Synopsis
# Copies all files and folders in $source folder to $destination folder, but with .copy inserted before the extension if the file already exists
param($source,$destination)

# create destination if it's not there ...
mkdir $destination -force -erroraction SilentlyContinue

foreach($original in ls $source -recurse) { 
  $result = $original.FullName.Replace($source,$destination)
  while(test-path $result -type leaf){ $result = [IO.Path]::ChangeExtension($result,"copy$([IO.Path]::GetExtension($result))") }

  if($original.PSIsContainer) { 
    mkdir $result -ErrorAction SilentlyContinue
  } else {
    copy $original.FullName -destination $result
  }
}
}
