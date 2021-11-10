#Find user based on employeeID
Get-AdUser -filter { employeeid -eq <#employeeID#> } |  Select-Object SamAccountName

#Find which OU a user is located
Get-ADUser -Identity <#enter username#> -Properties DistinguishedName | Select-Object DistinguishedName

#List all distribution group a user has
Get-ADPrincipalGroupMembership  <#Enter username#> | Select name
