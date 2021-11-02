
< #Audit AD based on specific OU, not from entire user lists #> 

#Paths
#Add more paths if you like by navigate to distinguished name from AD Attribute Editor 
# ***********************************************#
#Stores
$StorePath = 'OU=Harry Rosen Stores,OU=HarryRosen,DC=hri,DC=com'
#Central Office
$COPath = 'OU=HRCoffice,OU=HarryRosen,DC=hri,DC=com'
#Service Accounts
$SAPath = 'OU=ServiceAccounts,OU=HarryRosen,DC=hri,DC=com'
#Users 
$UsersPath = 'OU=Users,OU=HarryRosen,DC=hri,DC=com'
#mi 
$MIPath = 'OU=mi,DC=hri,DC=com'
# ***********************************************#

# *******Computer Paths*******#
#CO Computers
$COCompPath = 'OU=HR Coffice,OU=Harry Rosen Computers,DC=hri,DC=com'
#HR Stores
$StoreCompPath = 'OU=HR Stores,OU=Harry Rosen Computers,DC=hri,DC=com'
#Zegna Store
$ZegnaPath = 'OU=Zegna Stores,OU=Harry Rosen Computers,DC=hri,DC=com'
# ***********************************************#


#Lookups
# Replace the path to look up inactive users from a specific OU 
# ***********************************************#

#Inactive Users
$InactiveUsers = Search-ADAccount -AccountInactive -DateTime $InactiveDate -UsersOnly -SearchBase <#Enter path#> | Select-Object @{ Name="Username"; Expression={$_.SamAccountName} }, Name, LastLogonDate, DistinguishedName

#Expire Users

#Check for accounts that has password that's set to never expire
$SUSUsers = Get-ADUser -filter * -properties Name, PasswordNeverExpires -SearchBase <#Enter path#> | where { $_.passwordNeverExpires -eq $true } | Select-Object DistinguishedName,Name,Enabled


# ***********************************************#


#Export to CSV 
$UserS | Export-Csv <#Enter where you want to store your file#>

# Output
Write-Output <#Enter your look up#>




