function cim-ei {
<#
.SYNOPSIS
    Enumerate Instances of a class on a CIMOM via CIM-XML interface

.DESCRIPTION
    Primary use case of this function is to gather inventory and performance information from IT
    infrastructure assets. The inventory information feeds into capacity planning, troubleshooting,
    managing product life cycle, budgeting, vendor price negotiations and technology strategy in
    large enterprise environments. The output from this function would typically go into a datawarehouse
    front ended with a business intelligence platform such as COGNOS, QlikView, Business Objects, etc.

    The function queries any CIM server, called CIMOM, that supports the CIM-XML interface. It
    creates an XML message to encapsulate the CIM query, converts the message to byte stream and
    then sends it using HTTP POST method. The response byte stream is converted back to XML message
    and name value paris are parsed out. SMI-S is an instance of CIM, and is thus also fully supported.

    Tested against SAN devices such as EMC Symmetrix VMAX Fibre Channel Storage Array and Cisco MDS
    Fibre Channel switch. It can be used to query VMWARE vSphere vCenter, IBM XIV, NetApp Filer, EMC
    VNX Storage Array, HP Insight Manager, Dell OpenManage, HDS: USP, USPV, VSP, AMS, etc.

.NOTES
    Author: Parul Jain (paruljain@hotmail.com)
    Version: 0.1, 14th April, 2012
    Requires: PowerShell v2 or better

.EXAMPLE
    cim-ei -Class CIM_ComputerSystem -Device switch1 -user admin -Pass securepass

.EXAMPLE
    This works with EMC Symmetrix
    cim-ei -Class CIM_ComputerSystem -Device seserver -user admin -Pass '#1Password' -ns 'root/emc'
      
.PARAMETER class
    Mandatory. Information within CIM is classified into classes. The device documentation (or SNIA
    documntation in case of SMI-S) should list all the classes supported by the CIMOM. CIM_ComputerSystem
    class is available universally and is a good place to start testing.

.PARAMETER device
    Mandatory. IP address or DNS name of the device or CIMOM server if CIMOM runs separately

.PARAMETER user
    Mandatory. User ID authorized to perform queries. Most hardware vendors have a factory default

.PARAMETER pass
    Mandatory. Password for the user. Again most hardware vendors have a factory default for servicing the equipment

.PARAMETER port
    Optional. The TCP port number that the CIMOM is listening to. Default is used if not specified.

.PARAMETER ssl
    Optional switch. When used function will use HTTPS instead of default HTTP

.PARAMETER ns
    Optional. CIM namespace to use. Default is root/cimv2. EMC uses root/emc

.PARAMETER msg
    Optional switch. Returns CIM-XML response message instead of parsed name-value pairs for
    troubleshooting parsing if needed

.PARAMETER localOnly
    Optional switch. LocalOnly and Deep (Inheritance) switches work together to define precisely the properties
    that are to be returned. Properties from the specified class are always returned but properties from
    subclasses and superclasses of the specified class can be included or excluded as required.
 
.PARAMETER deep
    Optional switch. LocalOnly and Deep (Inheritance) switches work together to define precisely the properties
    that are to be returned. Properties from the specified class are always returned but properties from
    subclasses and superclasses of the specified class can be included or excluded as required.

.PARAMETER classOrigin
    Optional switch. Specifies whether the name of the class in which the property or method was defined
    (possibly a superclass of this one) should be included in the response.

.PARAMETER qualifiers
    Optional switch. Specifies whether or not qualifiers for each instance and property are to be returned.
#>
    
    [CmdletBinding()]

    Param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][String]$Class,
        [parameter(Mandatory=$true, ValueFromPipeline=$false)][String]$User,
        [parameter(Mandatory=$true, ValueFromPipeline=$false)][String]$Pass,
        [parameter(Mandatory=$true, ValueFromPipeline=$false)][String]$Device,
        [parameter(Mandatory=$false, ValueFromPipeline=$false)][String]$Port = '',
        [parameter(Mandatory=$false, ValueFromPipeline=$false)][Switch]$ssl,
        [parameter(Mandatory=$false, ValueFromPipeline=$false)][String]$ns = 'root/cimv2',
        [parameter(Mandatory=$false, ValueFromPipeline=$false)][Switch]$localOnly,
        [parameter(Mandatory=$false, ValueFromPipeline=$false)][Switch]$classOrigin,
        [parameter(Mandatory=$false, ValueFromPipeline=$false)][Switch]$deep,
        [parameter(Mandatory=$false, ValueFromPipeline=$false)][Switch]$qualifiers,
        [parameter(Mandatory=$false, ValueFromPipeline=$false)][Switch]$msg
    ) 

# CIM-XML message template
$messageText = @'
<?xml version="1.0" encoding="utf-8" ?>

<CIM CIMVERSION="2.0" DTDVERSION="2.0">

    <MESSAGE ID="1000" PROTOCOLVERSION="1.0">
        <SIMPLEREQ>
            <IMETHODCALL NAME="EnumerateInstances">
            </IMETHODCALL>
        </SIMPLEREQ>
    </MESSAGE>
</CIM>
'@

    # Parse the XML text into XMLDocument
    $message = [xml]($messageText)

    # Transform CIM-XML message based on supplied parameters
    $nsPathNode = $message.cim.message.SIMPLEREQ.IMETHODCALL.AppendChild($message.CreateElement('LOCALNAMESPACEPATH'))
    foreach ($path in $ns.split('/')) {
        $pathElement = $nsPathNode.AppendChild($message.CreateElement('NAMESPACE'))
        $pathElement.SetAttribute('NAME', $path)
    }
    
    $paramNode = $message.CIM.MESSAGE.SIMPLEREQ.IMETHODCALL
    $param = $paramNode.AppendChild($message.CreateElement('IPARAMVALUE'))
    $param.SetAttribute('NAME', 'ClassName')
    $paramValue = $param.AppendChild($message.CreateElement('CLASSNAME'))
    $paramValue.SetAttribute('NAME', $class)
    
    $param = $paramNode.AppendChild($message.CreateElement('IPARAMVALUE'))
    $param.SetAttribute('NAME', 'LocalOnly')
    $paramValue = $param.AppendChild($message.CreateElement('VALUE'))
    if ($localOnly) { $paramValue.InnerText = 'TRUE' } else { $paramValue.InnerText = 'FALSE' }
    
    $param = $paramNode.AppendChild($message.CreateElement('IPARAMVALUE'))
    $param.SetAttribute('NAME', 'IncludeClassOrigin')
    $paramValue = $param.AppendChild($message.CreateElement('VALUE'))
    if ($classOrigin) { $paramValue.InnerText = 'TRUE' } else { $paramValue.InnerText = 'FALSE' }
    
    $param = $paramNode.AppendChild($message.CreateElement('IPARAMVALUE'))
    $param.SetAttribute('NAME', 'DeepInheritance')
    $paramValue = $param.AppendChild($message.CreateElement('VALUE'))
    if ($deep) { $paramValue.InnerText = 'TRUE' } else { $paramValue.InnerText = 'FALSE' }

    $param = $paramNode.AppendChild($message.CreateElement('IPARAMVALUE'))
    $param.SetAttribute('NAME', 'IncludeQualifiers')
    $paramValue = $param.AppendChild($message.CreateElement('VALUE'))
    if ($qualifiers) { $paramValue.InnerText = 'TRUE' } else { $paramValue.InnerText = 'FALSE' }


    # Do not validate server certificate when using HTTPS
    # Amazing how easy it is to create a delegated function in PowerShell!
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    

    # Process other parameters and switches
    $protocol = 'http://'
    if ($ssl) { $protocol = 'https://' }

    if ($port -eq '' -and !$ssl) { $port = '5988' }
    if ($port -eq '' -and $ssl) { $port = '5989' }
     
    $url = $protocol + $device + ":" + $port

    # Instantiate .Net WebRequest class
    $req = [System.Net.WebRequest]::Create($url + '/cimom')
    $req.Method ='POST'
    
    # Add headers required by CIMOM
    $req.ContentType = 'application/xml;charset="UTF-8"'
    $req.Headers.Add("CIMProtocolVersion", "1.0")
    $req.Headers.Add('CIMOperation', 'MethodCall')
    $req.Headers.Add('CIMMethod', 'EnumerateInstances')
    $req.Headers.Add('CIMObject', $ns)

    # Encode and attach userID and password
    $uri = New-Object System.Uri($url)
    $nc = New-Object System.Net.NetworkCredential($user, $pass)
    $cc = New-Object System.Net.CredentialCache
    $cc.add($uri, 'Basic', $nc)
    $req.Credentials = $cc

    $enc = New-Object System.Text.UTF8Encoding
    $bytes = $enc.GetBytes($message.OuterXML)
    $req.ContentLength = $bytes.Length
    $reqStream = $req.GetRequestStream()
    $reqStream.Write($bytes, 0, $bytes.Length)
    $reqStream.Close()

    # Send the request
    try {
        $resp = $req.GetResponse()
    } catch [Net.WebException]  { throw($_.Exception.Message) }

    # Parse the response XML
    $reader = new-object System.IO.StreamReader($resp.GetResponseStream())
    $result = [xml]($reader.ReadToEnd())
    $reader.Close()

    # Create a temporary XML document to help parse out name value pairs
    # There are several other ways this can be accomplished
    $xdoc = new-object xml
    $rootnode = $xdoc.AppendChild($xdoc.CreateElement($class))

    foreach ($instance in @($result.CIM.MESSAGE.SIMPLERSP.IMETHODRESPONSE.IRETURNVALUE.'Value.NamedInstance')) {
        $node = $rootnode.AppendChild($xDoc.CreateElement('Property'))
        foreach ($prop in @($instance.instance.property)) {
            if ($prop.value -ne $null -and $prop.value -ne '') {
                $node.SetAttribute($prop.Name, $prop.value)
            }
        }
    }
    
    # Return CIM-XML response message or parsed out array of name value pairs
    if ($msg) { $result } else { $xdoc.$class.property }
}
