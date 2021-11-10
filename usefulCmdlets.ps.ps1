#Cause I keep hearing people saying they couldn't find a person on AD
#Usually finding by employeeID is easier


#Find user based on employeeID
#Play with it like how you play with CRM ID look up
Get-AdUser -filter { employeeid -eq <#employeeID#> } |  Select-Object SamAccountName

#Find which OU a user is located
Get-ADUser -Identity <#enter username#> -Properties DistinguishedName | Select-Object DistinguishedName

#List all distribution group a user has
Get-ADPrincipalGroupMembership  <#Enter username#> | Select name
