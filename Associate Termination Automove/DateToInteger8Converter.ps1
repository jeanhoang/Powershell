# PSDateToInteger8.ps1
# PowerShell script demonstrating how to convert a datetime value to the
# corresponding Integer8 (64-bit) value. The Integer8 value is the
# number of 100-nanosecond intervals (ticks) since 12:00 AM January 1,
# 1601, in Coordinated Univeral Time (UTC).
#
# ----------------------------------------------------------------------
# Copyright (c) 2011 Richard L. Mueller
# Hilltop Lab web site - http://www.rlmueller.net
# Version 1.0 - March 19, 2011
#
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the copyright owner above has no warranty, obligations,
# or liability for such use.

# Read Datetime value from command line or prompt for value.
Param ($strDate)
If ($strDate -eq $Null)
{
    $strDate = Read-Host "Date (Local Time)"
}

# Convert string to datetime.
$Date = [DateTime]"$strDate"

# Correct for daylight savings.
If ($Date.IsDaylightSavingTime)
{
    $Date = $Date.AddHours(-1)
}

# Convert the datetime value, in UTC, into the number of ticks since
# 12:00 AM January 1, 1601.
$Value = ($Date.ToUniversalTime()).Ticks - ([DateTime]"January 1, 1601").Ticks
$Value
