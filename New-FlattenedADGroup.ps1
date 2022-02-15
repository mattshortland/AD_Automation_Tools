           
          
function  New-FlattenedADGroup {

param (
[Parameter(Mandatory=$true,Position=0)][validatescript({get-ADGroup $_})][String]$sourceGroup,
[Parameter(Mandatory=$true,Position=1,ParameterSetName='Copy')][switch]$copy,
[Parameter(Mandatory=$true,Position=1,ParameterSetName='ReplaceSource')][switch]$replaceSource,
[Parameter(Mandatory=$true,Position=2,ParameterSetName='Copy')][string]$newGroupName,
[Parameter (Mandatory=$false,Position=2)][switch]$includeGroups
)

$newGroupMembers = Get-NestedADGroupMembership $SourceGroup -AsObject

if ($copy -eq $true)
    {
        $oldgroup = Get-ADGroup $SourceGroup -Properties *
        New-ADGroup -SamAccountName "$newGroupName" -Name "$newGroupName" -GroupCategory $oldgroup.GroupCategory -GroupScope $oldgroup.GroupScope -Path ($oldgroup.DistinguishedName -split "$($oldgroup.SamAccountName)," | Select-Object -Last 1)
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
.PARAMETER  Copy
Create a flattened copy of the group
.PARAMETER  replacesource
replace the source group wih a flattened version
.PARAMETER  newgroupname
If using the copy parameter choose a new group name
.PARAMETER  IncludeGroups
retains any groups directly nested in the source group
.INPUTS
None. You cannot pipe objects to New-FlattenedADGroup.
.OUTPUTS
None
.EXAMPLE
PS> New-FlattenedADGroup -SourceGroup nested1 -copy -newGroupName nested1-copy
.NOTES
Written by Matt Shortland
https://github.com/mattshortland/AD_Automation_Tools
#>

        
   }  
