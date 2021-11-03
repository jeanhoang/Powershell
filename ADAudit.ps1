
< #Audit AD based on specific OU, not from entire user lists #> 

#Generic#
# ***********************************************#
$GenericHR = 'OU=HarryRosen,DC=hri,DC=com'
$GenericHRComp = 'OU=HRStorePCs,DC=hri,DC=com'

# ***********************************************#
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


#Users Account Lookups
# Replace the path to look up inactive users from a specific OU 
# ***********************************************#

#Disabled User accounts (generic)
$DisabledUsers = Get-ADComputer -Filter {(Enabled -eq $False)} -ResultPageSize 2000 -ResultSetSize $null -SearchBase 'OU=HarryRosen,DC=hri,DC=com' -Properties Name, OperatingSystem

#Inactive Users
$InactiveUsers = Search-ADAccount -AccountInactive -DateTime $InactiveDate -UsersOnly -SearchBase <#Enter path#> | Select-Object @{ Name="Username"; Expression={$_.SamAccountName} }, Name, LastLogonDate, DistinguishedName

#Expired Users
$ExpiredAccount = Search-ADAccount -AccountExpired -UsersOnly -ResultPageSize 2000 -resultSetSize $null -SearchBase <#Enter path#>| Select-Object Name, SamAccountName, DistinguishedName, Account Expiration Date

#Check for accounts that has password that's set to never expire
$PWUsers = Get-ADUser -filter * -properties Name, PasswordNeverExpires -SearchBase <#Enter path#> | where { $_.passwordNeverExpires -eq $true } | Select-Object DistinguishedName,Name,Enable

# ***********************************************#


#Computer Account Lookups
# Replace the path to look up inactive users from a specific OU 
# ***********************************************#

#Find Disabled Comp Accounts
$ComputerAcc = Get-ADComputer -Filter {(Enabled -eq $False)} -ResultPageSize 2000 -ResultSetSize $null -Properties Name, OperatingSystem -SearchBase <#Enter path#> | Select-Object Name, SamAccountName
#$(Get-ADComputer 'computername').distinguishedName: exact path for comp 

#Generic computer# 

$GenericComputers = Get-ADComputer -Filter {(Enabled -eq $False)} -ResultPageSize 2000 -ResultSetSize $null -Properties Name, OperatingSystem -SearchBase 'CN=Computers,DC=hri,DC=com' | Select-Object Name, SamAccountName

# ***********************************************#

#Print Disabled MI Accs
# ***********************************************#

$DisabledMI = Get-ADUser -Filter {(Enabled -eq $False)} -ResultPageSize 2000 -ResultSetSize $null -Properties Name, OperatingSystem -SearchBase $MIPath| Select-Object Name, SamAccountName

# ***********************************************#



#Export to CSV 
$Users | Export-Csv <#Enter where you want to store your file#>

# Output
Write-Output $Users




