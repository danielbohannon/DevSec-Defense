trap [System.Management.Automation.RuntimeException]
{
    $entryException = $_
    
    if ($_.CategoryInfo.Category -eq [System.Management.Automation.ErrorCategory]::InvalidOperation)
    {
        if ($_.FullyQualifiedErrorId -eq "TypeNotFound")
        {
            $targetName = $_.CategoryInfo.TargetName
            
            try
            {
                $isUnresolvable = $global:__ambiguousTypeNames.Contains($targetName)
            }
            catch
            {
                throw $entryException
            }
            
            if ($isUnresolvable)
            {
                $message = New-Object System.Text.StringBuilder
                $message.AppendFormat("The type [{0}] is ambiguous. Specify one of the following: ", $targetName).AppendLine() | Out-Null
                
                [System.Type]::GetType("System.Management.Automation.TypeAccelerators")::Get.GetEnumerator() | ForEach-Object {
                    if (($_.Key.Split('.'))[-1] -eq $targetName)
                    {
                        $message.Append($_.Key).AppendLine() | Out-Null
                    }
                }
                
                $exception = New-Object System.Management.Automation.RuntimeException -ArgumentList $message.ToString()
                $errorId = "TypeNotFound"
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $targetObject = $_.TargetObject
                
                throw New-Object System.Management.Automation.ErrorRecord -ArgumentList $exception, $errorId, $errorCategory, $targetObject
            }
        }
    }
}

<#
    .SYNOPSIS
        Imports the types in the specified namespaces in the specified assemblies.

    .DESCRIPTION
        The Add-Namespace function adds a type accelerator for each type found in the specified namespaces in the specified assemblies that satisfy a set of conditions. For more information see the NOTES section.

    .PARAMETER Assembly
        The namespace to import.

    .PARAMETER Namespace
        Specifies one or more namespaces to import.

    .INPUTS
        System.Reflection.Assembly
            You can pipe an assembly to Add-Namespace.

    .OUTPUTS
        None
            This function does not return any output.

    .NOTES
        The type accelerator for the type is added if the type:
        
        - Has a base type which is not System.Attribute, System.Delegate or System.MulticastDelegate
        - Is not abstract
        - Is not an interface
        - Is not nested
        - Is public
        - Is visible
        - Is qualified by the namespace specified in the Namespace parameter
        
        This function also comes with an exception handler in the form of a trap block. Type name collisions occur when a type has the same name of another type which is in a different namespace. When this happens, the function adds or replaces the type accelerator for that type using its fully-qualified type name. If a type resolution occurs during runtime, the trap block will determine if the type was unresolved during any of the calls made to Add-Namespace and throw an exception listing valid replacements.
        
        The type accelerators added by this function exist only in the current session. To use the type accelerators in all sessions, add them to your Windows PowerShell profile. For more information about the profile, see about_profiles.
        
        Be aware that namspaces can span multiple assemblies, in which case you would have to import the namespace for each assembly that it exists in.
        
        This function will not attempt to add or replace types which already exist under the same name.
    
    .EXAMPLE
        C:\\PS> [System.Reflection.Assembly]::LoadWithPartialName("mscorlib") | Add-Namespace System.Reflection
        
        C:\\PS> [Assembly]::LoadWithPartialName("System.Windows.Forms")
        
        This example shows how to import namespaces from an assembly. The assembly must be loaded non-reflectively into the current application domain.
    
    .EXAMPLE
        C:\\PS> $assemblies = @([System.Reflection.Assembly]::LoadWithPartialName("mscorlib"), [System.Reflection.Assembly]::LoadWithPartialName("System"), [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms"), [System.Reflection.Assembly]::LoadWithPartialName("System.Xml"), [System.Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq"))
        
        C:\\PS> $assemblies | Add-Namespace System, System.Collections, System.Collections.Generic, System.Net, System.Net.NetworkInformation, System.Reflection, System.Windows.Forms, System.Xml.Linq
        
        This example shows how to import multiple namespaces from multiple assemblies.   
    
    .LINK
        about_trap
#>
function Add-Namespace
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [System.Reflection.Assembly]$Assembly,
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Namespace
    )
    
    BEGIN
    {
        if ($global:__ambiguousTypeNames -eq $null)
        { 
            $global:__ambiguousTypeNames = New-Object 'System.Collections.Generic.List[System.String]'
        }
        
        $genericRegex = [Regex]'(?<Name>.*)`\\d+'
        
        $typeAccelerators = [System.Type]::GetType("System.Management.Automation.TypeAccelerators")
        $typeDictionary = $typeAccelerators::Get
    }
    
    PROCESS
    {
        $_.GetTypes() | Where-Object { 
            ($_.BaseType -ne [System.Attribute]) -and 
            ($_.BaseType -ne [System.Delegate]) -and 
            ($_.BaseType -ne [System.MulticastDelegate]) -and 
            !$_.IsAbstract -and
            !$_.IsInterface -and 
            !$_.IsNested -and 
            $_.IsPublic -and 
            $_.IsVisible -and 
            ($Namespace -contains $_.Namespace)
        } | ForEach-Object { 
            $name = $_.Name
            $fullName = $_.FullName
        
            if ($_.IsGenericType)
            {
                if ($_.Name -match $genericRegex)
                {
                    $name = $Matches["Name"]
                }
                
                if ($_.FullName -match $genericRegex)
                {
                    $fullName = $Matches["Name"]
                }
            }
            
            if ($typeDictionary.ContainsKey($name))
            {
                if ($typeDictionary[$name] -eq $_)
                {
                    return
                }
            }
            
            if ($typeDictionary.ContainsKey($fullName))
            {
                if ($typeDictionary[$fullName] -eq $_)
                {
                    return
                }
            }
            
            if ($global:__ambiguousTypeNames.Contains($name))
            {
                $typeAccelerators::Add($fullName, $_)
                return
            }
            
            if ($typeDictionary.ContainsKey($name))
            {
                $type = $typeDictionary[$name]
                
                if ($_ -ne $type)
                {
                    $global:__ambiguousTypeNames.Add($name)
                    
                    $newName = $typeDictionary[$name].FullName
                    
                    if ($newName -match $genericRegex)
                    {
                        $newName = $Matches["Name"]
                    }
                    
                    $typeAccelerators::Remove($name)
                    $typeAccelerators::Add($newName, $type)
                    
                    $typeAccelerators::Add($fullName, $_)
                }
                
                return
            }
            
            $typeAccelerators::Add($name, $_)
        } | Out-Null
    }
    
    END
    {
        
    }
}

# Sample usage
# You can do this as an initialization task for your script

@(
    [System.Reflection.Assembly]::LoadWithPartialName("mscorlib"),
    [System.Reflection.Assembly]::LoadWithPartialName("System"),
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms"),
    [System.Reflection.Assembly]::LoadWithPartialName("System.Xml"),
    [System.Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq") 
) | Add-Namespace -Namespace `
    System, 
    System.Collections, 
    System.Collections.Generic, 
    System.Net, 
    System.Net.NetworkInformation, 
    System.Reflection, 
    System.Windows.Forms,
    System.Xml.Linq
