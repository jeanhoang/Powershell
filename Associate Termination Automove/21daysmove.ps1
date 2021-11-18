
$UserToBeDisabled = 'OU=Users-To Be Disabled,DC=hri,DC=com' 

$csvFile = Import-Csv -Path C:\Temp\21dayscheck.csv

$csvFile | ForEach{

    Move-ADObject -Identity $_.Path -TargetPath $UserToBeDisabled 

}



Write-Host "Completed"
