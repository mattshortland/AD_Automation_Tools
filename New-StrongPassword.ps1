Function New-StrongPassword {
    [CmdletBinding(DefaultParameterSetName='AsText')]


param (
[Parameter(Mandatory=$false,Position=0)][validatescript({$_ -ge 8 -and $_ -lt 129})][int]$PasswordLength=24,
[Parameter (Mandatory=$false,Position=1)][validatescript({$_ -ge 1 -and $_ -le 40})][int]$MinNonAlphaNumChars,
[Parameter (Mandatory=$false,Position=2,ParameterSetName='AsText')][switch]$AsText,
[Parameter (Mandatory=$false,ParameterSetName='AsSecureString')][switch]$AsSecureString,
[Parameter (Mandatory=$false,ParameterSetName='AsObject')][switch]$AsObject
)


If ($MinNonAlphaNumChars -eq $null)
    {$MinNonAlphaNumChars = (Get-Random -Minimum 1 -Maximum ([Math]::Round(($PasswordLength - 0.5) / 2 )))}
If ($MinNonAlphaNumChars -ge ( $PasswordLength -2 ))
    {$MinNonAlphaNumChars = ([Math]::Round( 2 * ($PasswordLength - 0.33) / 3 ))}

Add-Type -AssemblyName System.Web
$PassComplexCheck = $false
do {
$NewPassword=[System.Web.Security.Membership]::GeneratePassword($PasswordLength,$MinNonAlphaNumChars)
If ( ($NewPassword -cmatch "[A-Z\p{Lu}\s]") `
-and ($NewPassword -cmatch "[a-z\p{Ll}\s]") `
-and ($NewPassword -match "[\d]") `
-and ($NewPassword -match "[^\w]") `
-and ($NewPassword -notmatch "[\!\@\#\$\%\^\+]")
)
{
$PassComplexCheck=$True
}
} While ($PassComplexCheck -eq $false)

if ($AsSecureString -eq $True)
    { return (ConvertTo-SecureString $NewPassword -AsPlainText -Force) }
elseif ($AsObject -eq $true)
    { $PasswordObject = [PSCustomObject]@{
        'Text' = $NewPassword
        'Password'  = (ConvertTo-SecureString -String $NewPassword -AsPlainText -Force)
        }
       return $PasswordObject
    }
else { return ($NewPassword)}

<#

.SYNOPSIS

Creates A Strong Password.

.DESCRIPTION

Creates a strong password, defaults to 24 characters.  Can output the password as plaintext, secure string or an object containing both

.PARAMETER  AsText

Outputs the password as plain text (Default Behaviour)

.PARAMETER  AsSecureString

Outputs the password as secure string

.PARAMETER  AsObject

Outputs the password as an object, with the object property "text" being plaintext and "password" being a secure string

.PARAMETER  PasswordLength

Sets the Desired Password Length, with 8 being the minimum and 128 being the maximum


.PARAMETER  MinNonAlphaNumChars

Sets the minimum number of non-alphanumeric characters in the password, with 2 being the minimum and the smaller of 40 or two thirds of the total password length being the maximum. Omitting this parameter will choose a random number for this value

.INPUTS

None. You cannot pipe objects to New-StrongPassword.

.OUTPUTS

By default System.String. New-StrongPassword returns a string with the password
If you use the -AsSecureString flag it will output as a secure string
If you use the -AsObject flag it will output as an object containing two properties, .text (the plaintext) and .password (the secure string)

.EXAMPLE

PS> New-StrongPassword
DQKZdkOobAWXE>EE7;J5y>A&

.EXAMPLE

PS> New-StrongPassword -AsSecureString
System.Security.SecureString

.EXAMPLE

PS> New-StrongPassword -PasswordLength 15
EHEUFtpt16-bmag

.EXAMPLE

PS> New-StrongPassword -PasswordLength 12 -MinNonAlphaNumChars 8
2_[l:-=h_}}C

.EXAMPLE

PS> New-StrongPassword -PasswordLength 8 -MinNonAlphaNumChars 1
jRf5Lo>C

.EXAMPLE

PS> New-StrongPassword -PasswordLength 11 -AsObject

Text                            Password
----                            --------
mmLy5A;&CVN System.Security.SecureString

.EXAMPLE

PS> $username = Get-ADUser "Matt"
PS> $userpassword = New-StrongPassword -PasswordLength 16 -AsObject
PS> Set-ADAccountPassword -Identity $username -NewPassword $userpassword.password
PS> write-host "User $username has the password $($userpassword.text)"

User Matt has the password HMmY18kz8oHBs]sx

.NOTES

Written by Matt Shortland
https://github.com/mattshortland/AD_Automation_Tools

#>


}



