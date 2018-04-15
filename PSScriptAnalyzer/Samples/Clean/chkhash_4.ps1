# calculate SHA512 of file.

function Get-SHA512([System.IO.FileInfo] $file = $(throw 'Usage: Get-MD5 [System.IO.FileInfo]'))
{
  	$stream = $null;
  	$cryptoServiceProvider = [System.Security.Cryptography.SHA512CryptoServiceProvider];
  	$hashAlgorithm = new-object $cryptoServiceProvider
  	$stream = $file.OpenRead();
  	$hashByteArray = $hashAlgorithm.ComputeHash($stream);
  	$stream.Close();

  	## We have to be sure that we close the file stream if any exceptions are thrown.

  	trap
  	{
   		if ($stream -ne $null)
    		{
			$stream.Close();
		}
  		break;
	}	

 	foreach ($byte in $hashByteArray) { if ($byte -lt 16) {$result += “0{0:X}” -f $byte } else { $result += “{0:X}” -f $byte }}
	return [string]$result;
}

function noequal ( $first, $second)
{
    foreach($s in $second)
    {
        if ($first -eq $s) {return $false}
    }
    return $true
}

#   chkhash.ps1 [file(s)/dir #1] [file(s)/dir #2] ... [file(s)/dir #3] [-u] [-h [path of .xml database]]
#   -u updates the XML file database and exits
#   otherwise, all files are checked against the XML file database.
#   -h specifies location of xml hash database


$hashespath=".\\hashes.xml"
del variable:\\args3 -ea 0
del variable:\\args2 -ea 0
del variable:\\xfiles -ea 0
del variable:\\files -ea 0
del variable:\\exclude -ea 0
$args3=@()
$args2=$args
$nu = 0
$errs = 0
$fc = 0
$upd = $false
$create = $false

for($i=0;$i -lt $args2.count; $i++)
{
    if ($args2[$i] -like "-h*")                                             # -help specified?
    {
        "Usage:    .\\chkhash.ps1 [-h] [-u] [-c] [-x <file path of hashes .xml database>] [file(s)/dir #1] [file(s)/dir #2] ... [file(s)/dir #n] [-e <Dirs>]"
        "Options:  -h - Help display."
        "          -c - Create hash database. If .xml hash database does not exist, -c will be assumed."
        "          -u - Update changed files and add new files to existing database."
        "          -x - specifies .xml database file path to use. Default is .\\hashes.xml"
        "          -e - exclude dirs. Put this after the files/dirs you want to check with SHA512 and needs to be fullpath (e.g. c:\\users\\bob not ..\\bob)."
        ""
        "Examples: PS>.\\chkhash.ps1 c:\\ d:\\ -c -x c:\\users\\bob\\hashes\\hashes.xml"
        "          PS>.\\chkhash.ps1 c:\\users\\alice\\pictures\\sunset.jpg -a -x c:\\users\\alice\\hashes\\pictureshashes.xml"
        "          PS>.\\chkhash.ps1 c:\\users\\eve\\documents d:\\media\\movies -x c:\\users\\eve\\hashes\\private.xml"
        "          PS>.\\chkhash.ps1 c:\\users\\eve -x c:\\users\\eve\\hashes\\private.xml -e c:\\users\\eve\\hashes"
        ""
        "Note:     files in subdirectories of any specified directory are automatically processed."
        exit
    }
    if ($args2[$i] -like "-u*") {$upd=$true;continue}                       # Update and Add new files to database?
    if ($args2[$i] -like "-c*") {$create=$true;continue}                    # Create database specified?
    if ($args2[$i] -like "-x*") {$i++;$hashespath=$args2[$i];continue}      # Get hashes xml database path    
    if ($args2[$i] -like "-e*")                                             # Exclude files, dirs
    {
        do {
        $i++        
        if ($i -ge $args2.count) {break}
        $exclude+=@($args2[$i])                                             # collect array of excluded directories.
        if (($i+1) -ge $args2.count) {break}
        } while ($args2[$i+1] -notlike "-*")
        continue
    }
        
    $args3+=@($args2[$i])                                                   # Add files/dirs
}

"ChkHash.ps1 - .\\chkhash.ps1 -h for usage."
""

if ($args3.count -eq 0) {exit}

# Get list of files and SHA512 hash them.
"Enumerating files from specified locations..."

$files=@(dir -literalpath $args3 -recurse -ea 0 | ?{$_.mode -notmatch "d"} | ?{noequal $_.directoryname $exclude})              # Get list of files

if ($files.count -eq 0) {"No files found. Exiting."; exit}

if ($create -eq $true -or !(test-path $hashespath))                        # Create database?
{       
    # Create SHA512 hashes of files and write to new database
    
    $files = $files | %{write-host "Hashing $($_.fullname) ...";add-member -inputobject $_ -name SHA512 -membertype noteproperty -value $(get-SHA512 $_.fullname) -passthru}
    $files |export-clixml $hashespath    
    "Created $hashespath"
    "$($files.count) file hash(es) saved. Exiting."
    exit
}

$xfiles=@(import-clixml $hashespath)
"Loaded $($xfiles.count) file hash(es) from $hashespath"
    
$hash=@{}
for($x=0;$x -lt $xfiles.count; $x++)
{
    if ($hash.contains($xfiles[$x].fullname)) {continue}
    $hash.Add($xfiles[$x].fullname,$x)   
}
     
foreach($f in $files)
{
    $n=($hash.($f.fullname))
    if ($n -eq $null)
    {    
        $nu++                                           # increment needs/needed updating count
        if ($upd -eq $false) {"Needs to be added: `"$($f.fullname)`"";continue}                 # if not updating, then  continue
        
        "Hashing $($f.fullname) ..."
        
        # Create SHA512 hash of file
        
        $f=$f |%{add-member -inputobject $_ -name SHA512 -membertype noteproperty -value $(get-SHA512 $_.fullname) -passthru}  
        $xfiles+=@($f)                                  # then add file + hash to list
        continue
    }
    
    $f=$f |%{add-member -inputobject $_ -name SHA512 -membertype noteproperty -value $(get-SHA512 $_.fullname) -passthru}  
    
    # Update and continue is specified.
                                                                      
    $fc++                                               # increment files checked.
    if ($xfiles[$n].SHA512 -eq $f.SHA512)               # Check SHA512 for mixmatch.
    {
        continue
    }
    $errs++                                             # increment mixmatches
    if ($upd -eq $true) { $xfiles[$n]=$f; "Updated `"$($f.fullname)`"";continue}                                                   
    "Bad SHA-512 found: `"$($f.fullname)`""
}

if ($upd -eq $true)                                     # if database updated
{
    $xfiles|export-clixml $hashespath                   # write xml database
    "Updated $hashespath"
    "$nu file hash(es) added to database."
    "$errs file hash(es) updated in database."
    exit
}

"$errs SHA-512 mixmatch(es) found."
"$fc file(s) SHA512 matched." 
if ($nu -ne 0) {"$nu file(s) need to be added [run with -u option to Add file hashes to database]."}    
