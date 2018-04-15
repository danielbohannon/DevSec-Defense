###########################################################################
#
# NAME: Convert-CBZ2CBR.ps1
#
# AUTHOR: Neiljmorrow
# EMAIL: Neiljmorrow@gmail.com
#
# NOTE:	Written to use command line version of 7zip (http://7zip.com)
#	from the default install location. Please modify the path below
#	if necessary.
#
# COMMENT:
#
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the creator, owner above has no warranty, obligations,
# or liability for such use.
#
# VERSION HISTORY:
# 1.0 1/24/2009 - Initial release
#
###########################################################################

#set alias to command line version of 7zip
set-alias cbrzip "c:\\program files\\7-zip\\7z.exe"

#find all files in the immediate directory 
dir "*.cbz" | foreach-object{

	#Make a copy and rename as zip
	copy-item $_.name ($_.basename + ".zip")

	#unzip the file to a "temp" directory
	cbrzip -oTemp x ($_.basename + ".zip")
	
	#remove the zip file
	remove-item ($_.basename + ".zip")
	
	#rar the contents of the "temp" directory
	cbrzip a ($_.basename + ".rar") "temp"

	#remove the "temp" directory
	remove-item -r "temp"

	#rename the rar file to cbr	
	rename-item ($_.basename + ".rar") ($_.basename + ".cbr")
}

#remove 7zip alias
remove-item alias:cbrzip


