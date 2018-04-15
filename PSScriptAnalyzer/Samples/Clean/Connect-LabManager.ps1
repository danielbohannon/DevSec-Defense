function Ignore-SslErrors {
	# Create a compilation environment
	$Provider=New-Object Microsoft.CSharp.CSharpCodeProvider
	$Compiler=$Provider.CreateCompiler()
	$Params=New-Object System.CodeDom.Compiler.CompilerParameters
	$Params.GenerateExecutable=$False
	$Params.GenerateInMemory=$True
	$Params.IncludeDebugInformation=$False
	$Params.ReferencedAssemblies.Add("System.DLL") > $null
	$TASource=@'
	  namespace Local.ToolkitExtensions.Net.CertificatePolicy {
	    public class TrustAll : System.Net.ICertificatePolicy {
	      public TrustAll() { 
	      }
	      public bool CheckValidationResult(System.Net.ServicePoint sp,
	        System.Security.Cryptography.X509Certificates.X509Certificate cert, 
	        System.Net.WebRequest req, int problem) {
	        return true;
	      }
	    }
	  }
'@ 
	$TAResults=$Provider.CompileAssemblyFromSource($Params,$TASource)
	$TAAssembly=$TAResults.CompiledAssembly

	## We now create an instance of the TrustAll and attach it to the ServicePointManager
	$TrustAll=$TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll")
	[System.Net.ServicePointManager]::CertificatePolicy=$TrustAll
}

function New-ObjectFromProxy {
	param($proxy, $proxyAttributeName, $typeName)

	# Locate the assembly for $proxy
	$attribute = $proxy | gm | where { $_.Name -eq $proxyAttributeName }
	$str = "`$assembly = [" + $attribute.TypeName + "].assembly"
	invoke-expression $str

	# Instantiate an AuthenticationHeaderValue object.
	$type = $assembly.getTypes() | where { $_.Name -eq $typeName }
	return $assembly.CreateInstance($type)
}

function Connect-LabManager {
	param($server, $credential)

	# Log in to Lab Manager's web service.
	$server = "https://" + $server + "/"
	$endpoint = $server + "LabManager/SOAP/LabManager.asmx"
	$proxy = new-webserviceproxy -uri $endpoint -cred $credential

	# Before continuing we need to add an Authentication Header to $proxy.
	$authHeader = New-ObjectFromProxy -proxy $proxy -proxyAttributeName "AuthenticationHeaderValue" -typeName "AuthenticationHeader"
	$authHeader.username = $credential.GetNetworkCredential().UserName
	$authHeader.password = $credential.GetNetworkCredential().Password
	$proxy.AuthenticationHeaderValue = $authHeader
	return $proxy
}

# Examples:
# Run this command if your Lab Manager's certificate is untrusted but you want to connect.
# Ignore-SslErrors

# Connect to Lab Manager.
# $labManager = Connect-LabManager -server "demo.eng.vmware.com" -credential (get-credential)

# Find out what operations there are.
# $labManager | gm | where { $_.MemberType -eq "Method" }
# See http://www.vmware.com/pdf/lm30_soap_api_guide.pdf for help on arguments.

# List all library configurations.
# $labManager.ListConfigurations(1)

# Find all machines deployed from any library configuration.
# $labManager.ListConfigurations(1) | foreach { write-host ("For Configuration " + $_.id + ":"); $labManager.ListMachines($_.id) }
