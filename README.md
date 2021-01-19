# Update-TeamsFWRules
 Intune focused powershell script to create firewall rules for Microsoft Teams with enhanced logging.


Modified from Microsoft script found at: https://docs.microsoft.com/en-us/microsoftteams/get-clients#sample-powershell-script

As well as community script fouund at: https://github.com/mardahl/MyScripts-iphase.dk/blob/master/Update-TeamsFWRules.ps1

## DESCRIPTION

Must be run with elevated permissions.

Designed to be run as user assigned PowerShell Script from Intune, or as a Scheduled Task run as SYSTEM at user login.

The script will create a new inbound firewall rule for the currently logged in user. Requires PowerShell 3.0.

## OUTPUTS

Log file stored in %SystemDrive%\Windows\TEMP\log_Update-TeamsFWRules.txt

Log file is copied to users own TEMP dir IF execution is successful.

## EXAMPLE

.\Update-TeamsFWRule.ps1 -Force
Adds the required Teams Firewall Rules
Execute the script in SYSTEM context!