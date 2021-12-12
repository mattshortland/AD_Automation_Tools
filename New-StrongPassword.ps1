Function New-StrongPassword {
    [CmdletBinding(DefaultParameterSetName='AsText')]


param (
[Parameter(Mandatory=$true)][validatescript({<#Minimum 8 Characters for Passwords#> $_ -ge 8})][int]$PasswordLength,
[Parameter (Mandatory=$false,Position=0,ParameterSetName='AsText')][switch]$AsText,
[Parameter (Mandatory=$false,ParameterSetName='AsSecureString')][switch]$AsSecureString,
[Parameter (Mandatory=$false,ParameterSetName='AsObject')][switch]$AsObject
)

$NonAlphaNumChars = Get-Random -Minimum 1 -Maximum ($PasswordLength - 4)

Add-Type -AssemblyName System.Web
$PassComplexCheck = $false
do {
$NewPassword=[System.Web.Security.Membership]::GeneratePassword($PasswordLength,$NonAlphaNumChars)
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

New-StrongPassword -PasswordLength 15
New-StrongPassword -PasswordLength 15 -AsSecureString
New-StrongPassword -PasswordLength 15 -AsObject
(New-StrongPassword -PasswordLength 15 -AsObject).text
(New-StrongPassword -PasswordLength 15 -AsObject).password

