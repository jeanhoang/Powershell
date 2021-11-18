Run Windows Powershell ISE for the script

Objective: Move and disable users from the Users-ToBeDisabled within your preference of X amount of days to Users-Disabled OU

Retrieves user based on their LastLogonDate, accountExpires attribute is not considered for this to make the job simpler. Any users that has been moved to this OU should already have an expiration day and should have been moved within 21-30 days after their termination. 

After disabling the users, the second command look for any disabled users within the OU and move them to the Users-Disabled OU.

The query is then exported to a csv file. You can modify the name/path of this file to your preference. 

Objects in the csv file is retrieved to be disabled and moved. To add extra cautious, the -WhatIf cmdlet is added add the end of the commands that disable and move users. This will print the result of what's about to be moved/disabled to the terminal screen. Compare this screen to CSV before removing the -WhatIf cmdlet to finish the moving and disabling process. 
