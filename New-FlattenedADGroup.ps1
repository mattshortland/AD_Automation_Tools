           
function  New-FlattenedADGroup {

param (
[Parameter(Mandatory=$true,Position=0)][validatescript({get-ADGroup $_})][String]$sourceGroup,
[Parameter(Mandatory=$true,Position=1,ParameterSetName='newGroupName')][string]$newGroupName,
[Parameter(Mandatory=$false,Position=2,ParameterSetName='newGroupName')][switch]$Force,
[Parameter(Mandatory=$true,Position=1,ParameterSetName='ReplaceSource')][switch]$replaceSource,
[Parameter (Mandatory=$false,Position=3)][switch]$includeGroups
)

$newGroupMembers = Get-NestedADGroupMembership $SourceGroup -AsObject

if ($newGroupName -ne $null)
    {
        $oldgroup = Get-ADGroup $SourceGroup -Properties *
        Try { New-ADGroup -SamAccountName "$newGroupName" -Name "$newGroupName" -GroupCategory $oldgroup.GroupCategory -GroupScope $oldgroup.GroupScope -Path ($oldgroup.DistinguishedName -split "$($oldgroup.SamAccountName)," | Select-Object -Last 1) -ErrorAction Ignore}
        Catch { if ($Force -ne $true)  
                { 
                    Write-Error "the group $newGroupName already exists, use the -Force parameter to replace or choose a new group name" 
                    return
                }
            }
    }

if ($replaceSource -eq $true)
    {
        $newGroupName = $sourceGroup
    }

$newGroupMembers | ForEach-Object {
        if ($_.objectClass -ne "group") {Add-ADGroupMember -Identity $newGroupName -Members $_.samaccountname -Confirm:$false -ErrorAction Ignore}
        if ($IncludeGroups -ne $true) {if ($_.objectClass -eq "group" -and $_.FromGroup -eq $SourceGroup) {Remove-ADGroupMember -identity $newGroupName -Members $_.samaccountname -Confirm:$false -ErrorAction Ignore}}
        if ($IncludeGroups -eq $true) {if ($_.objectClass -eq "group" -and $_.FromGroup -eq $SourceGroup) {Add-ADGroupMember -identity $newGroupName -Members $_.samaccountname -Confirm:$false -ErrorAction Ignore}}
    }

<#
.SYNOPSIS
Flattens AD Groups. Relies on the Get-NestedADGroupMembership function
.DESCRIPTION
Will enumerate nested groups and create a flat copy or replace the nested copy with a flat version
.PARAMETER  SourceGroup
The Group that you use as reference
.PARAMETER  newgroupname
Using the newGroupName parameter will create a copy of the group and allow you to choose a new group name
.PARAMETER  replacesource
replace the source group wih a flattened version
.PARAMETER  Force
If using the newGroupName parameter: if you choose a new group name that already exists you will replace the exsisting group membership (updates an existing group)
.PARAMETER  IncludeGroups
retains any groups directly nested in the source group
.INPUTS
None. You cannot pipe objects to New-FlattenedADGroup.
.OUTPUTS
None
.EXAMPLE
PS> New-FlattenedADGroup -SourceGroup nested1 -newGroupName nested1-copy
.NOTES
Written by Matt Shortland
https://github.com/mattshortland/AD_Automation_Tools
#>

        
   }  
