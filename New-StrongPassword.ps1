<#
Examples

New-StrongPassword
    generates a 24 character random password as plaintext
New-StrongPassword -AsSecureString
    generates a 24 character random password as a secure string
New-StrongPassword -PasswordLength 15
    generates a 15 character random password as plaintext
New-StrongPassword 15
    generates a 15 character random password as plaintext 
New-StrongPassword -PasswordLength 8 -MinNonAlphaNumChars 1
    generates an 8 character random password as plaintext, with at least 1 character not being alpha-numeric
New-StrongPassword 8 1 -AsSecureString
    generates an 8 character random password as a secure string, with at least 1 character not being alpha-numeric
New-StrongPassword -PasswordLength 12 -AsSecureString
    generates a 12 character random password as a secure string
New-StrongPassword -PasswordLength 11 -AsObject
    generates a 12 character random password as a PSCustomObject, with $_.text being the plaintext and $_.password being the secure string
$userpassword = New-StrongPassword -PasswordLength 16 -AsObject
Set-ADAccountPassword -Identity $username -NewPassword $userpassword.password
write-host "User $username has the password $($userpassword.text)"
    Here we show using the secure string property for the password change, and the plaintext property being used to output to the screen

#>

Function New-StrongPassword {
    [CmdletBinding(DefaultParameterSetName='AsText')]


param (
[Parameter(Mandatory=$false,Position=0)][validatescript({<#Minimum 8 Characters for Passwords#> $_ -ge 8})][int]$PasswordLength=24,
[Parameter (Mandatory=$false,Position=1)][validatescript({<#Minimum 1 Non AlphaNumeric Character for Passwords#> $_ -ge 1})][int]$MinNonAlphaNumChars,
[Parameter (Mandatory=$false,Position=2,ParameterSetName='AsText')][switch]$AsText,
[Parameter (Mandatory=$false,ParameterSetName='AsSecureString')][switch]$AsSecureString,
[Parameter (Mandatory=$false,ParameterSetName='AsObject')][switch]$AsObject
)

If ($MinNonAlphaNumChars -eq $null)
    {$MinNonAlphaNumChars = (Get-Random -Minimum 1 -Maximum ($PasswordLength - 4))}
If ($MinNonAlphaNumChars -ge $PasswordLength)
    {$MinNonAlphaNumChars = ($PasswordLength - 4)}

Add-Type -AssemblyName System.Web
$PassComplexCheck = $false
do {
$NewPassword=[System.Web.Security.Membership]::GeneratePassword($PasswordLength,$MinNonAlphaNumChars)
If ( ($NewPassword -cmatch "[A-Z\p{Lu}\s]") `
-and ($NewPassword -cmatch "[a-z\p{Ll}\s]") `
-and ($NewPassword -match "[\d]") `
-and ($NewPassword -match "[^\w]")
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
}
