[Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null

#Version History
#v1.0   - Chad Miller - Initial release
#Converts Image Files to icon files
#Adapted from WinForm C# code by Haresh Ambaliya
#http://code.msdn.microsoft.com/Convert-Image-file-to-Icon-c927d9f7


function ConvertTo-Icon
{
    [cmdletbinding()]
    param([Parameter(Mandatory=$true, ValueFromPipeline = $true)] $Path)
    
    process{
        if ($Path -is [string])
        { $Path = get-childitem $Path }
           
        $Path | foreach {
            $image = [System.Drawing.Image]::FromFile($($_.FullName))

            $FilePath =  "{0}\\{1}.ico" -f $($_.DirectoryName), $($_.BaseName)
            $stream = [System.IO.File]::OpenWrite($FilePath)

            $bitmap = new-object System.Drawing.Bitmap $image
            $bitmap.SetResolution(72,72)
            $icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
            $icon.Save($stream)
            $stream.Close()
        }
    }
      
 }
