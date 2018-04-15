function add-OLPublicFolder {
   param (
      [string]$PFName,                                                     #Name of the new Public Folder
      $PFType,                                                             #Type of the new Public Folder
      [string]$PFParent = "\\")                                             #Parentfolder of the new Public Folder
   begin {                                                                 #Outlook Constants to assign the needed values for the foldertypes
      [int]$olFolderInbox = 6                     
      [int]$olFolderCalendar = 9
      [int]$olFolderContacts = 10
      [int]$olFolderJournal = 11
      [int]$olFolderNotes = 12
      [int]$olFolderTasks = 13
      [int]$olPublicFoldersAllPublicFolders = 18
   
      $outlook = new-object -ComObject Outlook.Application                 #init Outlook Com Object
      $namespace = $outlook.GetNamespace("MAPI")                           #get MAPI namespace
                                                          
      # navigate to the folder "All Public Folders"
      $olObjAllPublicRootFolders = $namespace.GetDefaultFolder($olPublicFoldersAllPublicFolders)
   }
   
   process{
      #inner function
      #########################################################################   
      function script:get-OLPublicFolderByPath {
         param ([string]$FolderPath = $(throw "Error 2: mandatory parameter '-FolderPath'"))
         
         $Folder = $null                                                   #init of empty OL folderobject
         $FoldersArray = @{}                                               #force init of empty array
         
         #trim single or eading pairs of backslash
         If (($FolderPath).substring(0,2) -eq "\\\\") {$FolderPath = ($FolderPath.substring(2,$FolderPath.length - 2))}
         If (($FolderPath).substring(0,1) -eq "\\") {$FolderPath = ($FolderPath.substring(1,$FolderPath.length - 1))}
         
         #fill folderpath into array even if it is only one element
         if ($FolderPath.Contains("\\") -eq $true){$FoldersArray = $FolderPath.Split("\\")}
         else{$FoldersArray[0] = $FolderPath}
            
         $folders = $olObjAllPublicRootFolders.Folders                     #map root public folders
         for ($i = 0; $i -le ($FoldersArray.length - 1); $i++){            #for each element of the folderpath array
            $folders | %{                                                  #push the folders into the pipeline
               if ($_.name -eq $FoldersArray[$i]) {                        #if the objectname equals the current element of the folderpath array
                  $folders = $_.Folders                                    #get the child items into $folders
                  if ($i -eq ($FoldersArray.length - 1)) {return $_}       #return the last element of the folderpath array 
               }                                                       
            }
         }
      }   
      #########################################################################   

      if ($_){                                                             #if function is used in the pipeline you need to check the input 
            if ($_.PFName -ne $null){                                      #name of the public folder
               $PFName = $_.PFName}                                        #from first element of the object
            else{throw "Error 3: mandatory parameter '-PFName'"}           #no name, no public folder!
                                                                         
            if ($_.PFType -ne $null){                                      #type of the public folder
                  $PFType = $_.PFType                                      #assign the correct values for foldertypes
                  switch ($PFType) {                                       #based on the provided string
                     MAIL {$PFType = $olFolderInbox; break}              
                     CALENDAR {$PFType = $olFolderCalendar; break}
                     CONTACT {$PFType = $olFolderContacts; break}
                     JOURNAL {$PFType = $olFolderJournal; break}
                     NOTE {$PFType = $olFolderNotes; break}
                     TASK {$PFType = $olFolderTasks; break}
                     default{                                              #and throw an error if you get garbage
            throw "Unknown public folder type in optional parameter '-PFType'`
The supported public folder types are`
Mail, Calendar, Contact, Task, Note and Journal`
If no type is specified the default is Mail`
The value was: $PFType"}
                  }
               }
            else{$PFType = $olFolderInbox}                                 #empty parameter $PFType
                  
            if ($_.PFParent -ne $null){                                    #get desired position of the public folder
               $PFParent = $_.PFParent}                                    #from input
            else{$PFParent = "\\"}                                          #and make it root if nothing is provided
         
      }
      else{
         if ($PFType -eq $null){$PFType = $olFolderInbox}                  #set default to mailfolder if param for $PFType was empty
         else{
            switch ($PFType) {
               MAIL {$PFType = $olFolderInbox; break}
               CALENDAR {$PFType = $olFolderCalendar; break}
               CONTACT {$PFType = $olFolderContacts; break}
               JOURNAL {$PFType = $olFolderJournal; break}
               NOTE {$PFType = $olFolderNotes; break}
               TASK {$PFType = $olFolderTasks; break}
               default{
                  throw "Unknown public folder type in optional parameter '-PFType'`
The supported public folder types are`
Mail, Calendar, Contact, Task, Note and Journal`
If no type is specified the default is Mail`
The value was: $PFType"
                  }
            }      
         }      
      }

      if ($PFParent -eq "\\"){                                              #root public folder or one somewhere down the tree? Anyway, map to the parentfolder of the new folder
         $ParentFolder = $olObjAllPublicRootFolders}                       #root public folder
      else{$ParentFolder = get-OLPublicFolderByPath -FolderPath $PFParent} #use the inline function to traverse the public folders
                                                               
      $ParentFolder.Folders.Add($PFName, $PFType)                          #magic happens here ;-)
      Write-Host "Public folder $PFName created in path $PFParent."   
      $ParentFolder = $null                                                #reset parent folder to avoid wrong assignment for the next object
   }
   
   end{                                                                    #cleanup, cleanup, cleanup...
      $PFParent = $null
      $olObjAllPublicRootFolders = $null
      $namespace = $null
      $outlook = $null
   }
}
