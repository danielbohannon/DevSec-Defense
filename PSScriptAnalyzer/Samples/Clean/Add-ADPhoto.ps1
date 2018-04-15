#Add-ADPhoto   Powershell v1 compatibile script for updating
#user thumbnailphoto attribute.  Resizes input photo to recommended
#dimensions and size.  Only updates for the currently logged in user.
#This is a script for user self service.

#Author: Nathan Linley
#Site: http://myitpath.blogspot.com

$infile = $args[0]
$aspect = $args[1]

function usage {
	write-host "Usage: Add-ADPhoto filename [aspect]"
	write-host "   Provide the name of an image file in your current directory."
	write-host "   If you wish to preserve the aspect ratio of the image, type"
	write-host "   1 after your file name.  Images are resized to the recommended"
	write-host "   96x96, converted to JPG and set to 70% quality to limit size."
	exit 

}
$imagefile = (pwd).path + "\\" + $infile
$imagefileout = (pwd).path + "\\adout.jpg"

##############################################################################
#Check to see if the argument for filename was provided, and that it exists###
##############################################################################
if ([string]::isnullorempty($infile) -or -not (test-path $imagefile)) {
	&usage
}


###############################
#Remove any old converted file#
###############################
if (test-path $imagefileout) {
	del -path $imagefileout -ErrorAction "silentlycontinue"
}

$Image = New-Object -ComObject Wia.ImageFile
$ImageProcessor = New-Object -ComObject Wia.ImageProcess


##########################################################
#Try loading the file, if its not an image this will fail#
##########################################################
$Image.LoadFile($ImageFile)

if (-not $?) { &usage }


#############################################################
#Create filters, set aspect ratio setting, change dimensions#
#to max 96pixels, convert to JPG and set quality            #
#############################################################
$Scale = $ImageProcessor.FilterInfos.Item("Scale").FilterId
$ImageProcessor.Filters.Add($Scale)
$Qual = $ImageProcessor.FilterInfos.Item("Convert").FilterID
$ImageProcessor.Filters.Add($qual)

if ([string]::isnullorempty($aspect) -or [string]$aspect -ne "1") {
	$ImageProcessor.Filters.Item(1).Properties.Item("PreserveAspectRatio") = $false
} else {
	$ImageProcessor.Filters.Item(1).Properties.Item("PreserveAspectRatio") = $true
}

$ImageProcessor.Filters.Item(1).Properties.Item("MaximumHeight") = 96
$ImageProcessor.Filters.Item(1).Properties.Item("MaximumWidth") = 96
$ImageProcessor.Filters.Item(2).Properties.Item("FormatID") = "{B96B3CAE-0728-11D3-9D7B-0000F81EF32E}"

####################################################################
#Drop image quality until it meets the size recommendation of 10kb #
####################################################################
$quality = 80
do {
	Remove-Item -path $imagefileout -ErrorAction "silentlycontinue"
	$ImageProcessor.Filters.Item(2).Properties.Item("Quality") = $quality
	$Image = $ImageProcessor.Apply($Image)
	$Image.SaveFile($ImageFileOut)
	[byte[]]$imagedata = get-content $imagefileout -encoding byte
	$quality -= 10
} while ($imagedata.length -gt 10kb)


#####################################################################
#Find domain, and Account distinguished name.  Open user object, add#
#thumbnailphoto data and save.
#####################################################################
$de = new-object directoryservices.directoryentry("LDAP://" + $env:logonserver.substring(2))
$ds = new-object directoryservices.directorysearcher($de)
$ds.filter = "(&(objectclass=user)(samaccountname=" + $env:username + "))"
$myaccount = $ds.findone()
$de = new-object directoryservices.directoryentry($myaccount.path)
$de.properties["Thumbnailphoto"].clear()
$de.properties["Thumbnailphoto"].add($imagedata) |out-null
$de.setinfo()
Write-Host "Photo has been uploaded"


