Import-Module ActiveDirectory
#Paths
#Users-ToBe-Disabled Path
$User2BDis = 'OU=Users-To Be Disabled,DC=hri,DC=com'
#Users-Disabled Path/ Target OU 
$UserDis = 'OU=Users-Disabled,DC=hri,DC=com'

#Define days - within 90 days
$Date = (Get-Date).AddDays(-60)

#Look up any users within 90 days
$Users = Get-ADUser -Filter {((Enabled -eq $true) -and (LastLogonDate -lt $date))} -Properties LastLogonDate -SearchBase $User2BDis| select samaccountname, Name, LastLogonDate | Sort-Object LastLogonDate 

#Export this users to a csv file for manual checking
<#****************************** Important ************************************************#>
#You should be checking this csv file before running the disable cmd  
$Users | Export-Csv -Path C:\Temp\60daysbatch.csv -NoTypeInformation

#Import names from the CSV file
$Import_csv = Import-Csv -Path C:\Temp\60daysbatch.csv

 $Import_csv | ForEach-Object {

    $movedUsers = $_."samaccountname"
    $DN = (Get-ADUser -Identity $movedUsers).DistinguishedName

    #Disable all names from the csv
    #Add -WhatIf at the end of the line to double check before disabling
    Get-ADUser -Identity $movedUsers| Disable-ADAccount -WhatIf
}

#Look up disabled users from Users-ToBe-Disabled and move them
#Add -WhatIf at the end of the line to double check before moving
Get-ADUser -filter {Enabled -eq $false } -SearchBase $User2BDis | Foreach-object {
  Move-ADObject -Identity $_.DistinguishedName -TargetPath $UserDis -WhatIf
}

Write-Host "Completed disabling and moving"
