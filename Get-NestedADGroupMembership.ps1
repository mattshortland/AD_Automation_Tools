function  Get-NestedADGroupMembership {
[CmdletBinding(DefaultParameterSetName='AllMembers')]

param (
[Parameter(Mandatory=$true,Position=0)][String]$GroupName,
[Parameter (Mandatory=$false,Position=1,ParameterSetName='NoGroups')][switch]$NoGroups,
[Parameter (Mandatory=$false,Position=1,ParameterSetName='AllMembers')][switch]$AllMembers,
[Parameter (Mandatory=$false,Position=1,ParameterSetName='Groups')][switch]$Groups,
[Parameter (Mandatory=$false,Position=1,ParameterSetName='AsObject')][switch]$AsObject
)

    $Global:DataOutput  = @()

    function  SubGet-NestedADGroupMembership {

      param (
        [Parameter()][string]$GroupName
            )

      $GroupMembers = Get-ADGroupMember -Identity  $GroupName -ErrorAction stop
      $GroupMembers | foreach {  

          if ($_.objectClass  -eq 'group') { SubGet-NestedADGroupMembership  -GroupName $_.name }
           
                  $Global:DataOutput += [pscustomobject]@{
                    SamAccountName = $_.SamAccountName
                    FromGroup = @($GroupName)
                    objectClass = $_.objectClass
                    Name = $_.Name
                    distinguishedName = $_.distinguishedName
                    objectGUID  = $_.objectGUID 
                    SID = $_.SID
                  }
             }
     

    }
   
    SubGet-NestedADGroupMembership $GroupName

    $duplicates = ($Global:DataOutput | Group-Object -Property samaccountname | Where-Object {$_.count -gt 1}| ForEach-Object {$_.group })
    
    if ($duplicates.count -ge 1)
        {
            foreach ($duplicate in $duplicates)
                {
                    $duplicates | Where-Object {$_.samaccountname -eq $duplicate.SamAccountName} | ForEach-Object { 
                
                        if ($_.Fromgroup[0] -ne $duplicate.FromGroup[0])
                            {

                                $duplicate.FromGroup += $_.FromGroup[0]
                                $duplicate.FromGroup = ($duplicate.FromGroup | Sort-Object)

                        
                            }
                    }
           
                }
        }

  $Global:DataOutput = ($Global:DataOutput | Sort-Object -Property samaccountname -Unique)

  if ($NoGroups -eq $True)
    { return ($Global:DataOutput | Where-Object {$_.objectClass -ne "Group"} | Select-Object samaccountname,fromgroup,objectClass) }
elseif ($AllMembers -eq $True)
    { return ($Global:DataOutput | Select-Object samaccountname,fromgroup,objectClass) }
elseif ($Groups -eq $True)
    { return ($Global:DataOutput | Where-Object {$_.objectClass -eq "Group"} | Select-Object samaccountname,fromgroup,objectClass) }
elseif ($AsObject -eq $True)
    { return $Global:DataOutput}
else { return ($Global:DataOutput | Select-Object samaccountname,fromgroup,objectClass) }


<#
.SYNOPSIS
Gets nested group membership.
.DESCRIPTION
Will recursively enumerate group membership and display the members and from which group their access is provisioned
.PARAMETER  GroupName
The Group that you wish to enumerate recursively
.PARAMETER  NoGroups
Removes nested groups from the output, but the objects contained within are displayed
.PARAMETER  AllMembers (Default Behaviour)
Outputs all nested members including groups
.PARAMETER  Groups
Outputs only the groups nested within the chosen group
.PARAMETER  AsObject
Returns the full set of objects and additional attributes (SID, distinguishedname and objectGUID)
.INPUTS
None. You cannot pipe objects to Get-NestedADGroupMembership.
.OUTPUTS
By default three attributes samaccountname,fromgroup,objectClass
If you use the -AsObject flag it will additionally output SID, distinguishedname and objectGUID
.EXAMPLE
PS> Get-NestedADGroupMembership nested4b
SamAccountName FromGroup  objectClass
-------------- ---------  -----------
A175082        {nested4b} user       
A175083        {nested4b} user       
nested4c       {nested4b} group       
A175084        {nested4c} user
.EXAMPLE
PS> Get-NestedADGroupMembership nested4b -noGroups
SamAccountName FromGroup  objectClass
-------------- ---------  -----------
A175082        {nested4b} user       
A175083        {nested4b} user       
A175084        {nested4c} user
.EXAMPLE
PS> Get-NestedADGroupMembership nested4b -groups
SamAccountName FromGroup  objectClass
-------------- ---------  -----------
nested4c       {nested4b} group       
.EXAMPLE
PS> Get-NestedADGroupMembership nested4b -AsObject
FromGroup         : {nested4b}
objectClass       : user
Name              : Smith, John (A175082)
distinguishedName : CN=Smith\, John (A175082),OU=LABUsers,DC=lab,DC=notrecognised,DC=com
objectGUID        : 7a0cbafa-b6b4-4368-a3d4-a26c01cb8ecd
SID               : S-1-5-21-2699654466-974688084-2534585574-1580

SamAccountName    : A175083
FromGroup         : {nested4b}
objectClass       : user
Name              : Johnson, Paul (A175083)
distinguishedName : CN=Johnson\, Paul (A175083),OU=LABUsers,DC=lab,DC=notrecognised,DC=com
objectGUID        : 81aa0fbc-6fc6-4716-adcb-e02444a9a974
SID               : S-1-5-21-2699654466-974688084-2534585574-1581

 .
 .
 .
.NOTES
Written by Matt Shortland
https://github.com/mattshortland/AD_Automation_Tools
#>

        
   }        
