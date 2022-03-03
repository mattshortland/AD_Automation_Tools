$Savelocation = "c:\temp\DomainVitals"
$forestname = "contoso.com"

import-module activedirectory
Import-Module grouppolicy

$Forest = Get-ADForest $forestname
$forest | Export-Clixml "$Savelocation\Forest.xml"
foreach ($domainname in $Forest.domains)
    {
        New-Item -ItemType Directory -Path $Savelocation -Name $domainname
        $domain = Get-ADDomain -Server $domainname
        $dcs = Get-ADDomainController -filter * -Server $domain.dnsroot
        $trusts = Get-ADTrust -Server $domain.dnsroot -Filter *
        $ous = Get-ADOrganizationalUnit -Server $domain.dnsroot -Filter * -Properties canonicalname
        $sites = get-adreplicationsite -Server $domain.dnsroot -Filter *
        $subnets = Get-ADReplicationSubnet -Server $domain.dnsroot -Filter *

        $domain | Export-Clixml "$Savelocation\$domainname\domain.xml"
        $dcs | Export-Clixml "$Savelocation\$domainname\dcs.xml"
        $trusts | Export-Clixml "$Savelocation\$domainname\trusts.xml"
        $ous | Export-Clixml "$Savelocation\$domainname\OUs.xml"
        $sites | Export-Clixml "$Savelocation\$domainname\sites.xml"
        $subnets | Export-Clixml "$Savelocation\$domainname\subnets.xml"

        Remove-Item Variable:\sites
        Remove-Item Variable:\subnets
        Remove-Item Variable:\trusts

        $ous.canonicalname -replace '/','\' -replace "$domainname","OU_Structure"  | sort-object | % {New-Item "$savelocation\$domainname\$_" -ItemType Directory}

        New-Item -ItemType Directory -Path "$Savelocation\$domainname" -Name "GPOs"
        $gpos = get-gpo -All
        ForEach ($gpo in $gpos)
                {
                $gpoxml = Get-GPOReport $gpo.id -ReportType Xml 
                $gpoxml | Out-File "$savelocation\$domainname\GPOs\$($gpo.DisplayName).xml"
                $gpoxml = [xml]$gpoxml
                if ($gpoxml.gpo.linksto)
                    {
                     foreach ($gpolink in $gpoxml.gpo.linksto)
                        {
                            Copy-Item -Path "$savelocation\$domainname\GPOs\$($gpo.DisplayName).xml" -Destination "$Savelocation\$domainname\$( $gpolink.sompath -replace '/','\' -replace $domainname,"OU_Structure" )\$($gpo.DisplayName).xml"
                        }
                    }
                else { Rename-Item -Path "$savelocation\$domainname\GPOs\$($gpo.DisplayName).xml" -NewName "$savelocation\$domainname\GPOs\UNLINKED_$($gpo.DisplayName).xml"}
        
                }
        Remove-Item Variable:\gpos
        Remove-Item Variable:\gpo
        Remove-Item Variable:\gpoxml

        $ACLProperties = @()
        ForEach($OU In $OUs){
            $OUPath = "AD:\" + $OU.DistinguishedName
            $ACLs = (Get-Acl -Path $OUPath).Access
            ForEach($ACL in $ACLs){
                If ($ACL.IsInherited -eq $False){
                
                $ACLProperties += [pscustomobject] @{
                        "ACL" = $ACL
                        "OU" = $OU.DistinguishedName
                        }
                }
            }
       
        }

        $ACLProperties | Export-Clixml "$Savelocation\$domainname\OU_ACLs.xml"
        Remove-Item Variable:\ACLProperties

        Get-ADUser -Server $domain.dnsroot -Filter * -Properties * | Export-Clixml "$Savelocation\$domainname\users.xml"
        Get-ADGroup -Server $domain.dnsroot -Filter * -Properties * | Export-Clixml "$Savelocation\$domainname\groups.xml"
        Get-ADComputer -Server $domain.dnsroot -Filter * -Properties * | Export-Clixml "$Savelocation\$domainname\computers.xml"

    }

    $parentpath =  (Get-Item $savelocation).psparentpath
    Compress-Archive -LiteralPath $savelocation -DestinationPath "$parentpath\$($Forest.name -replace "\.","_")-DomainVitals.zip"
