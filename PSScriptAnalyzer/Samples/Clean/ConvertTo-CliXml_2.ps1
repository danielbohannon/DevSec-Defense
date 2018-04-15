#requires -version 2.0
function ConvertTo-CliXml {
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject[]]$InputObject
    )
    begin {
        $type = [type]::gettype("System.Management.Automation.Serializer")
        $ctor = $type.getconstructor("instance,nonpublic", $null, @([System.Xml.XmlWriter]), $null)
        $sw = new-object System.IO.StringWriter
        $xw = new-object System.Xml.XmlTextWriter $sw
        $serializer = $ctor.invoke($xw)
        $method = $type.getmethod("Serialize", "nonpublic,instance", $null, [type[]]@([object]), $null)
        $done = $type.getmethod("Done", [System.Reflection.BindingFlags]"nonpublic,instance")
    }
    process {
        try {
            [void]$method.invoke($serializer, $InputObject)
        } catch {
            write-warning "Could not serialize $($InputObject.gettype()): $_"
        }
    }
    end {    
        [void]$done.invoke($serializer, @())
        $sw.ToString()
		$xw.Close()
		$sw.Dispose()
    }
}
