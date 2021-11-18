﻿# PSGenericADO.ps1
# PowerShell program to use ADO to query Active Directory.
#
# ----------------------------------------------------------------------
# Copyright (c) 2011 Richard L. Mueller
# Hilltop Lab web site - http://www.rlmueller.net
# Version 1.0 - July 30, 2011
# Version 1.1 - August 5, 2011 - Handle more SID values.
# Version 1.2 - August 14, 2011 - Convert logonHours to local time.
#                                 Modify for PowerShell V1.
# Version 1.3 - September 19, 2012 - Modify rounding of local time
#               zone bias to handle fractions of hour properly.
# Version 1.4 - March 20, 2013 - Fix function OctetToGUID.
# Version 1.5 - April 2, 2015 - Improve Function OctetToHours, add functions.
#
# The program prompts for the DN of the base of the query, the LDAP
# syntax filter, and a comma delimited list of attribute values to be
# retrieved. Displays attribute values for objects matching filter in
# base selected.
#
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the copyright owner above has no warranty, obligations,
# or liability for such use.

Trap
{
    If ("$_".StartsWith("There is no such object on the server"))
    {
        "Invalid Base for the Query: $BaseDN"
        Break
    }
    If ("$_".StartsWith("An invalid dn syntax has been specified"))
    {
        "Invalid Base for the Query: $BaseDN"
        Break
    }
    If ("$_".StartsWith("The server is not operational"))
    {
        "DC not found: $BaseDN"
        Break
    }
    If ("$_".EndsWith("search filter is invalid."))
    {
        "Invalid LDAP Syntax Filter: $Filter"
        Break
    }
    If ("$_".StartsWith("The directory service is unavailable"))
    {
        "Invalid LDAP Syntax Filter: $Filter"
        Break
    }
    If ("$_".StartsWith("An operations error occurred."))
    {
        "You cannot retrieve the value of a multi-valued operational attribute"
        Break
    }
    If ("$_".StartsWith("The attribute syntax specified to the directory service is invalid."))
    {
        "An LDAP Syntax Filter cannot include operational attributes: $Filter"
        Break
    }
    If ("$_".StartsWith("Unknown error (0x80005000)"))
    {
        "Domain cannot be contacted. Check network connection and if you are authenticated to a domain."
        Break
    }
    If ("$_".StartsWith("The specified domain either does not exist or"))
    {
        "Domain cannot be contacted: $BaseDN"
        Break
    }
    If ("$_".StartsWith("A referral was returned from the server"))
    {
        "Base of the query cannot be contacted: $BaseDN"
        Break
    }
    If ("$_".StartsWith("There is no such object on the server"))
    {
        "Invalid Base for the Query: $BaseDN"
        Break
    }
    "Error: $_"; Break;
}

$Colon = ":"
# Check for optional parameters indicating output should be in csv format instead
# of text, or only a count of the number of records retrieved should be reported,
# or if the scope of the query should be "oneLevel" rather than "subTree".
$Csv = $True
$Count = $False
$Scope = "subTree"

$Abort = $False
ForEach ($Arg In $Args)
{
    Switch ($Arg.ToLower())
    {
        {($_ -eq "/csv") -Or ($_ -eq "-csv")} {$Csv = $True}
        {($_ -eq "/count") -Or ($_ -eq "-count")} {$Count = $True}
        {($_ -eq "/onelevel") -Or ($_ -eq "-onelevel")} {$Scope = "oneLevel"}
        Default {"Invalid parameter: $Arg"; $Abort = $True; Break}
    }
}
If ($Abort -eq $True) {Break}
If (($Csv -eq $True) -And ($Count -eq $True))
{
    "Output cannot be in CSV format if Count is requested"
    Break
}

# Retrieve local Time Zone bias from machine registry in hours.
# This bias does not change with Daylight Savings Time.
$Bias = (Get-ItemProperty `
    -Path HKLM:\System\CurrentControlSet\Control\TimeZoneInformation).Bias
# Account for negative bias.
If ($Bias -gt 10080){$Bias = $Bias - 4294967296}
$Bias = [Math]::Round($Bias/60, 0, [MidpointRounding]::AwayFromZero)

# Create an array of 168 bytes, representing the hours in a week.
$LH = New-Object 'object[]' 168

Function OctetToGUID ($Octet)
{
    # Function to convert Octet value (byte array) into string GUID value.
    $GUID = [GUID]$Octet
    Return $GUID.ToString("B")
}

Function OctetToHours ($Octet)
{
    # Function to convert Octet value (byte array) into binary string
    # representing logonHours attribute. The 168 bits represent 24 hours
    # per day for 7 days, Sunday through Saturday. The values are converted
    # into local time. If the bit is "1", the user is allowed to logon
    # during that hour. If the bit is "0", the user is not allowed to logon.
    For ($j = 0; $j -le 20; $j = $j + 1)
    {
        For ($k = 7; $k -ge 0; $k = $k - 1)
        {
            $m = 8*$j + $k - $Bias
            If ($m -lt 0) {$m = $m + 168}
            If ($m -gt 167) {$m = $m - 168}
            If ($Octet[$j] -band [Math]::Pow(2, $k)) {$LH[$m] = "1"}
            Else {$LH[$m] = "0"}
        }
    }

    For ($j = 0; $J -le 20; $j = $J + 1)
    {
        $n = 8*$j
        Switch ($j)
        {
            0 {$Hours = " M   4    8   N    4   8`r`n    Sunday:    " + [String]::Join("", $LH[$n..($n + 7)])}
            3 {$Hours = $Hours + "`r`n    Monday:    " + [String]::Join("", $LH[$n..($n + 7)])}
            6 {$Hours = $Hours + "`r`n    Tuesday:   " + [String]::Join("", $LH[$n..($n + 7)])}
            9 {$Hours = $Hours + "`r`n    Wednesday: " + [String]::Join("", $LH[$n..($n + 7)])}
            12 {$Hours = $Hours + "`r`n    Thursday:  " + [String]::Join("", $LH[$n..($n + 7)])}
            15 {$Hours = $Hours + "`r`n    Friday:    " + [String]::Join("", $LH[$n..($n + 7)])}
            18 {$Hours = $Hours + "`r`n    Saturday:  " + [String]::Join("", $LH[$n..($n + 7)])}
           Default {$Hours = $Hours + "-" + [String]::Join("", $LH[$n..($n + 7)])}
        }
    }
    Return $Hours
}

Function UAC ($Flag)
{
    # Function to evaluate the userAccountControl attribute.
    $Setting = ""
    If ($Flag -band 0x02) {$Setting = $Setting + "AccountDisabled "}
    If ($Flag -band 0x08) {$Setting = $Setting + "HomeDirReqd "}
    If ($Flag -band 0x10) {$Setting = $Setting + "LockedOut "}
    If ($Flag -band 0x20) {$Setting = $Setting + "PwdNotReqd "}
    If ($Flag -band 0x40) {$Setting = $Setting + "PwdCannotChg "}
    If ($Flag -band 0x80) {$Setting = $Setting + "EncriptedTextPwdAllowed "}
    If ($Flag -band 0x100) {$Setting = $Setting + "TempDuplAccount "}
    If ($Flag -band 0x200) {$Setting = $Setting + "NormalAccount "}
    If ($Flag -band 0x800) {$Setting = $Setting + "InterdomnainTrustAcct "}
    If ($Flag -band 0x1000) {$Setting = $Setting + "WorkstationTrustAcct "}
    If ($Flag -band 0x2000) {$Setting = $Setting + "ServerTrustAcct "}
    If ($Flag -band 0x10000) {$Setting = $Setting + "PwdDoesNotExpire "}
    If ($Flag -band 0x20000) {$Setting = $Setting + "MNSLogonAcct "}
    If ($Flag -band 0x40000) {$Setting = $Setting + "SmartcardReqd "}
    If ($Flag -band 0x80000) {$Setting = $Setting + "TrustedForDelgation "}
    If ($Flag -band 0x100000) {$Setting = $Setting + "NotDelegated "}
    If ($Flag -band 0x200000) {$Setting = $Setting + "UseDESKeyOnly "}
    If ($Flag -band 0x400000) {$Setting = $Setting + "RequirePreauth "}
    If ($Flag -band 0x800000) {$Setting = $Setting + "PwdExpired "}
    If ($Flag -band 0x1000000) {$Setting = $Setting + "TrustedToAuthForDelegation "}
    If ($Flag -band 0x4000000) {$Setting = $Setting + "PartialSecretsAcct "}
    If ($Flag -band 0x8000000) {$Setting = $Setting + "UseAESKeysOnly "}
    Return " (" + $Setting.Trim() + ")"
}

Function GroupType ($Flag)
{
    $GT = ""
    # Function to retrieve group type from the groupType attribute.
    If ($Flag -band 0x01) {$GT = $GT + "Built-in "}
    If ($Flag -band 0x02) {$GT = $GT + "Global "}
    If ($Flag -band 0x04) {$GT = $GT + "Local "}
    If ($Flag -band 0x08) {$GT = $GT + "Universal "}
    If ($Flag -band 0x10) {$GT = $GT + "APP_BASIC "}
    If ($Flag -band 0x20) {$GT = $GT + "APP_QUERY "}
    If ($Flag -band 0x80000000) {$GT = $GT.Trim() + "/Security"}
    Else {$GT = $GT.Trim() + "/Distribution"}
    Return " ($GT)"
}

Function SearchFlags ($Flag)
{
    $SF= ""
    # Function to evaluate the searchFlags attribute.
    If ($Flag -band 0x01) {$SF = $SF + "Indexed "}
    If ($Flag -band 0x02) {$SF = $SF + "IndexedEachContainer "}
    If ($Flag -band 0x04) {$SF = $SF + "InANRSet "}
    If ($Flag -band 0x08) {$SF = $SF + "PreservedInTombstone "}
    If ($Flag -band 0x10) {$SF = $SF + "CopiedWhenObjectCopied "}
    If ($Flag -band 0x20) {$SF = $SF + "TupleIndex "}
    If ($Flag -band 0x40) {$SF = $SF + "VLVIndex "}
    Return " (" + $SF.Trim() + ")"
}

Function SystemFlags ($Flag)
{
    $SysF = ""
    # Function to evaluate the systemFlags attribute.
    If ($Flag -band 0x01) {$SysF = $SysF + "AttrReplicated/NTDSCrossRefObj "}
    If ($Flag -band 0x02) {$SysF = $SysF + "ReplToGC/DomainCrossRefObj "}
    If ($Flag -band 0x04) {$SysF = $SysF + "AttrConstructed "}
    If ($Flag -band 0x10) {$SysF = $SysF + "AttrInBaseSchema "}
    If ($Flag -band 0x02000000) {$SysF = $SysF + "DelImmediately "}
    If ($Flag -band 0x04000000) {$SysF = $SysF + "CannotBeMoved "}
    If ($Flag -band 0x08000000) {$SysF = $SysF + "CannotBeRenamed "}
    If ($Flag -band 0x10000000) {$SysF = $SysF + "CanBeMovedWithRestrictions "}
    If ($Flag -band 0x20000000) {$SysF = $SysF + "CanBeMoved "}
    If ($Flag -band 0x40000000) {$SysF = $SysF + "CanBeRenamed "}
    If ($Flag -band 0x80000000) {$SysF = $SysF + "CannotBeDeleted "}
    Return " (" + $SysF.Trim() + ")"
}

Function SAMType ($Flag)
{
    # Function to evaluate the sAMAccountType attribute.
    Switch ($Flag)
    {
        0x10000000 {$ST = "GroupObject"}
        0x10000001 {$ST = "NonSecurityGroupObject"}
        0x20000000 {$ST = "AliasObject"}
        0x20000001 {$ST = "NonSecurityAliasObject"}
        0x30000000 {$ST = "UserAccount"}
        0x30000001 {$ST = "MachineAccount"}
        0x30000002 {$ST = "TrustAccount"}
        0x40000000 {$ST = "AppBasicAccount"}
        0x40000001 {$ST = "AppQueryAccount"}
    }
    Return " ($ST)"
}

Function InstanceType ($Flag)
{
    $IT= ""
    # Function to evaluate the searchFlags attribute.
    If ($Flag -band 0x01) {$IT = $IT + "NCHead "}
    If ($Flag -band 0x02) {$IT = $IT + "ReplicaNotInstantiated "}
    If ($Flag -band 0x04) {$IT = $IT + "Writeable "}
    If ($Flag -band 0x08) {$IT = $IT + "NCAboveHeld "}
    If ($Flag -band 0x10) {$IT = $IT + "NCBeingConstructed "}
    If ($Flag -band 0x20) {$IT = $IT + "NCBeingRemoved "}
    Return " (" + $IT.Trim() + ")"
}

$Searcher = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.PageSize = 200
$Searcher.SearchScope = $Scope

# Prompt for base of query.
$BaseDN = Read-Host "Enter DN of base of query, or blank for entire domain"
If ($BaseDN -eq "")
{
    # Default to the entire domain.
    $Base = New-Object System.DirectoryServices.DirectoryEntry
    $BaseDN = $Base.distinguishedName
}
Else
{
    If ($BaseDN.ToLower().Contains("dc=") -eq $False)
    {
        $Domain = New-Object System.DirectoryServices.DirectoryEntry
        $BaseDN = $BaseDN + "," + $Domain.distinguishedName
        $BaseDN = $BaseDN.Replace(",,", ",").Replace("/,", "/")
    }
    $Base = New-Object System.DirectoryServices.DirectoryEntry "LDAP:// $BaseDN"
}
$Searcher.SearchRoot = $Base

# Prompt for LDAP syntax filter.
$Filter = Read-Host "Enter LDAP syntax filter"
If ($Filter.StartsWith("(") -eq $False) {$Filter = "(" + $Filter}
If ($Filter.EndsWith(")") -eq $False) {$Filter = $Filter + ")"}
$Searcher.Filter = $Filter

$Searcher.PropertiesToLoad.Add("distinguishedName") > $Null
If ($Count -eq $False)
{
    # Prompt for attributes.
    $Attributes = Read-Host "Enter comma delimited list of attribute values to retrieve"
    # Remove any spaces.
    $Attributes = $Attributes -replace " ", ""
    $arrAttrs = $Attributes.Split(",")
    ForEach ($Attr In $arrAttrs)
    {
        If ($Attr -ne "") { $Searcher.PropertiesToLoad.Add($Attr) > $Null }
    }
}

If ($Csv -eq $False)
{
    "Base of query: $BaseDN ($Scope)"
    "Filter: $Filter"
    If ($Count -eq $False)
    {
        "Attributes: $Attributes"
    }
    "----------------------------------------------"
}
Else
{
    # Header line.
    $Line = "DN"
    ForEach ($Attr In $arrAttrs)
    {
        If ($Attr -ne "") { $Line = $Line + "," + $Attr }
    }
    $Line
}

# Run the query.
$Results = $Searcher.FindAll()

If ($Count -eq $True)
{
    $Records = $Results.Count
    "Number of objects found: $Records"
    Break
}

# Enumerate resulting recordset.
$Records = 0
ForEach ($Result In $Results)
{
    $Records = $Records + 1
    $DN = $Result.Properties.Item("distinguishedName")
    If ($Csv -eq $True)
    {
        # Any double quote characters in the DN must be doubled.
        $Line = """" + $DN[0].Replace("""", """""") + """"
    }
    Else
    {
        "DN: " + $DN
    }
    # Retrieve all requested attributes.
    ForEach ($Attr In $arrAttrs)
    {
        If ($Attr -ne "")
        {
            $Values = $Result.Properties.Item($Attr)
            If ($Values[0] -eq $Null)
            {
                # Attribute has no value.
                If ($Csv -eq $True) {$Line = "$Line,<no value>"}
                Else {"  $Attr$Colon <no value>"}
            }
            Else
            {
                # Attribute might be multi-valued. Values will be semicolon delimited.
                # Values will only be quoted if they are String.
                $Multi = ""
                $Quote = $False
                ForEach ($Value In $Values)
                {
                    Switch ($Value.GetType().Name)
                    {
                        "Int64"
                        {
                            # Attribute is Integer8 (64-bit).
                            If (($Value -ge [TimeSpan]::MaxValue.Ticks) `
                                -or ($Value -le [TimeSpan]::MinValue.Ticks))
                            {
                                # Value is maximum 64-bit value 2^63 - 1,
                                # or minimum 64-bit value -2^63.
                                If ($Csv -eq $True)
                                    {
                                    If ($Multi -eq "") {$Multi = "<never>"}
                                    Else {$Multi = "$Multi;<Never>"}
                                }
                                Else {"  $Attr$Colon <never>"}
                            }
                            Else
                            {
                                If (($Value -gt 120000000000000000) `
                                    -and ($Value -le [DateTime]::MaxValue.Ticks))
                                {
                                    # Integer8 value is a date, greater than
                                    # April 07, 1981, 9:20 PM UTC
                                    # and less than December 31, 9999 12:00 PM
                                    $Date = [Datetime]$Value
                                    If ($Csv -eq $True)
                                    {
                                        If ($Multi -eq "")
                                        {
                                            $Multi = $Date.AddYears(1600).ToLocalTime()
                                        }
                                        Else
                                        {
                                            $Multi = "$Multi;" `
                                                + $Date.AddYears(1600).ToLocalTime()
                                        }
                                    }
                                    Else
                                    {
                                        "  $Attr$Colon " + '{0:n0}' -f $Value `
                                            + " (" + $Date.AddYears(1600).ToLocalTime() + ")"
                                    }
                                }
                                Else
                                {
                                    # Integer8 value, not a date.
                                    If ($Value -lt 0)
                                    {
                                        # Assume a TimeSpan.
                                        $Span = [TimeSpan](-$Value)
                                        If ($Csv -eq $True)
                                        {
                                            If ($Multi -eq "") {$Multi = $Span}
                                            Else {$Multi = "$Multi;" + $Span}
                                        }
                                        Else
                                        {
                                            "  $Attr$Colon " + '{0:n0}' -f $Value `
                                                + " ($Span Days.Hours:Minutes:Seconds)"
                                        }
                                    }
                                    Else
                                    {
                                        # Large integer value, between 0 and 120,000,000,000,000,000.
                                        If ($Csv -eq $True)
                                        {
                                            If ($Multi -eq "") {$Multi = '{0:n0}' -f $Value}
                                            Else {$Multi = "$Multi;" + '{0:n0}' -f $Value}
                                        }
                                        Else {"  $Attr$Colon " + '{0:n0}' -f $Value}
                                    }
                                }
                            }
                        }
                        "Byte[]"
                        {
                            # Attribute is a byte array (OctetString).
                            If (($Value.Length -eq 16) `
                                -and ($Attr.ToUpper().Contains("GUID") -eq $True))
                            {
                                # GUID value.
                                If ($Csv -eq $True)
                                {
                                    If ($Multi -eq "") {$Multi = $(OctetToGUID $Value)}
                                    Else {$Multi = "$Multi;" + $(OctetToGUID $Value)}
                                }
                                Else {"  $Attr$Colon " + $(OctetToGUID $Value)}
                            }
                            Else
                            {
                                If (($Value.Length -eq 21) -and ($Attr -eq "logonHours"))
                                {
                                    # logonHours attribute, byte array of 168 bits.
                                    # One binary bit for each hour of the week, in UTC.
                                    If ($Csv -eq $True)
                                    {
                                        If ($Multi -eq "") {$Multi = $(OctetToHours $Value)}
                                        Else {$Multi = "$Multi;" + $(OctetToHours $Value)}
                                    }
                                    Else {"  $Attr$Colon " + $(OctetToHours $Value)}
                                }
                                Else
                                {
                                    If (($Value[0] -eq 1) -and (`
                                        (($Value[1] -eq 1) -and ($Value.Length -eq 12)) `
                                        -or (($Value[1] -eq 2) -and ($Value.Length -eq 16)) `
                                        -or (($Value[1] -eq 4) -and ($Value.Length -eq 24)) `
                                        -or (($Value[1] -eq 5) -and ($Value.Length -eq 28))))
                                    {
                                        # SID value.
                                        $SID = New-Object System.Security.Principal.SecurityIdentifier $Value, 0
                                        If ($Csv -eq $True)
                                        {
                                            If ($Multi -eq "") {$Multi = $SID}
                                            Else {$Multi = "$Multi;$SID"}
                                        }
                                        Else {"  $Attr$Colon $SID"}
                                    }
                                    Else
                                    {
                                        # Byte array.
                                        If ($Csv -eq $True)
                                        {
                                            If ($Multi -eq "") {$Multi = $Value}
                                            Else {$Multi = "$Multi;$Value"}
                                        }
                                        Else {"  $Attr$Colon $Value"}
                                    }
                                }
                            }
                        }
                        "String"
                        {
                            # String value. Enclose in quotes in case there are embedded
                            # commas. Any double quote characters in the string must
                            # be doubled.
                            $Quote = $True
                            If ($Csv -eq $True)
                            {
                                # Embedded quotes must be doubled.
                                $Value = $Value.Replace("""", """""")
                                # Multi-line values must have carriage return line
                                # feed characters replaced with ";".                         
                                $Value = $Value.Replace("`r`n", ";")
                                If ($Multi -eq "") {$Multi = $Value}
                                Else {$Multi = "$Multi;$Value"}
                            }
                            Else {"  $Attr$Colon $Value"}
                        }
                        "Int32"
                        {
                            # 32-bit integer.
                            If (($Attr.ToLower() -eq "useraccountcontrol") -Or `
                                ($Attr.ToLower() -eq "msds-user-account-control-constructed"))
                            {
                                # If attribute is userAccountControl, append settings.
                                $Value = "$Value" + $(UAC($Value))
                            }
                            If ($Attr.ToLower() -eq "grouptype")
                            {
                                # If attribute is groupType, append settings.
                                $Value = "$Value" + $(GroupType($Value))
                            }
                            If ($Attr.ToLower() -eq "searchflags")
                            {
                                # If attribute is searchFlags, append settings.
                                $Value = "$Value" + $(SearchFlags($Value))
                            }
                            If ($Attr.ToLower() -eq "systemflags")
                            {
                                # If attribute is systemFlags, append settings.
                                $Value = "$Value" + $(SystemFlags($Value))
                            }
                            If ($Attr.ToLower() -eq "samaccounttype")
                            {
                                # If attribute is sAMAccountType, append settings.
                                $Value = "$Value" + $(SAMType($Value))
                            }
                            If ($Attr.ToLower() -eq "instancetype")
                            {
                                # If attribute is instanceType, append settings.
                                $Value = "$Value" + $(InstanceType($Value))
                            }
                            If ($Csv -eq $True)
                            {
                                If ($Multi -eq "") {$Multi = '{0:n0}' -f $Value}
                                Else {$Multi = "$Multi;" + '{0:n0}' -f $Value}
                            }
                            Else {"  $Attr$Colon " + '{0:n0}' -f $Value}
                        }
                        "Boolean"
                        {
                            # Boolean value.
                            If ($Csv -eq $True)
                            {
                                If ($Multi -eq "") {$Multi = "$Value"}
                                Else {$Multi = "$Multi;$Value"}
                            }
                            Else {"  $Attr$Colon $Value"}
                        }
                        "DateTime"
                        {
                            # Datetime value.
                            If ($Csv -eq $True)
                            {
                                If ($Multi -eq "") {$Multi = "$Value"}
                                Else {$Multi = "$Multi;$Value"}
                            }
                            Else {"  $Attr$Colon $Value"}
                        }
                        Default
                        {
                            If ($Csv -eq $True)
                            {
                                If ($Multi -eq "") {$Multi = "<not supported> (" + $Value.GetType().Name + ")"}
                                Else {Multi = "$Multi;<not supported> (" + $Value.GetType().Name + ")"}
                            }
                            Else {"  $Attr$Colon <not supported> (" + $Value.GetType().Name + ")"}
                        }
                    }
                }
                If ($Csv -eq $True)
                {
                    # Enclose values in double quotes if necessary.
                    If ($Quote -eq $True) {$Line = "$Line,""$Multi"""}
                    Else {$Line = "$Line,$Multi"}
                }
            }
        }
    }
    If ($Csv -eq $True) {$Line}
}
If ($Csv -eq $True) { 
    $Results | Export-Csv -Path C:\Temp\21dayscheck.csv
}

If ($Csv -eq $False) {"Number of objects found: $Records"}
