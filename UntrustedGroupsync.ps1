$workingdir = "c:\temp"
$syncgroups = import-csv "$workingdir\syncgroups.csv" 
$username = "domain\prd_tr1_analyzer"
$password = Get-Content "$workingdir\pass.txt" | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PsCredential($username,$password)
$userOU = ""



$syncusers = get-aduser -SearchBase "$userOU" -filter * -Properties memberof

$mappingfile = @()
foreach ($syncuser in $syncusers) {
    foreach ($groupname in $syncuser.memberof) {
        $mappingfile += [PSCustomObject]@{
        'samaccountname' = $syncuser.samaccountname
        'groupname'  = $( $groupname -replace "CN=","" -split "," | Select-Object -First 1 )
        }
    }
}

for($i = 29; $i -gt 0; $i--) {
move-item "$workingdir\Group_Sync_Backup_$($i).csv" "$workingdir\Group_Sync_Backup_$($i+1).csv"  -ErrorAction Ignore
}

move-item "$workingdir\Group_Sync.csv" "$workingdir\Group_Sync_Backup_1.csv" -ErrorAction Ignore

$mappingfile | export-csv "$workingdir\Group_Sync.csv"
$oldmappingfile = Import-Csv "$workingdir\Group_Sync_Backup_1.csv"


$changelist = ($mappingfile | Add-Member -PassThru Source 1) + ( $oldmappingfile | Add-Member -PassThru Source 2) | ForEach-Object { $_ | Add-Member -PassThru Hash "$($_.samaccountname+ "+" + $_.groupname)" } |Group-Object hash | ForEach-Object {
    if ($_.Count -eq 1) {
        $_.Group[0] | Add-Member -PassThru Status @{ 1 = 'add'; 2 = 'remove' }[$_.Group[0].Source]
    }
} | Select-Object samaccountname,groupname,status

$changelist | ForEach-Object { $_ | Where-Object {$syncgroups.name -contains $_.groupname }}

$changelist | export-csv $workingdir\changelist.csv -Force

$syncusers | Select-Object samaccountname,enabled | Export-Csv $workingdir\Sync_Users_Enabled.csv


$grouplist = $mappingfile.groupname | Sort-Object -Unique | get-adgroup -Properties name,description

