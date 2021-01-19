<#
.SYNOPSIS
    Creates firewall rules for Microsoft Teams.
    Modified from Microsoft script found at: https://docs.microsoft.com/en-us/microsoftteams/get-clients#sample-powershell-script
    As well as community script fouund at: https://github.com/mardahl/MyScripts-iphase.dk/blob/master/Update-TeamsFWRules.ps1
.DESCRIPTION
    Must be run with elevated permissions. 
    Designed to be run as user assigned PowerShell Script from Intune, or as a Scheduled Task run as SYSTEM at user login. 
    The script will create a new inbound firewall rule for the currently logged in user. 
    Requires PowerShell 3.0.
.INPUTS
  None
.OUTPUTS
  Logs are stored within Event Viewer > Applications and Services Logs > Teams Firewall Rules
  The log source is "Teams Firewall Rules Script"
.NOTES
  Version:        1.5
  Author:         Matthew Drummond
  Creation Date:  18 January 2021
.EXAMPLE
  .\Update-TeamsFWRule.ps1 -Force
  Adds the required Teams Firewall Rules
  Execute the script in SYSTEM context!
#>

#Requires -Version 3
#Requires -Runasadministrator

#region Declarations

#Enable forced rule creation, to cleanup any rules the user might have made, and set the standards imposed by this script (suggested setting $True).
$Force = $True

#Declare the Event viwer "source" for events being written to log.
$EventSource = "Teams Firewall Rules Script"

#Declare the title of the log that log entries are being commited to
$LogTitle = "Teams Firewall Rules"

# Provision new source for Event log
New-EventLog -LogName $LogTitle -Source $EventSource -ErrorAction SilentlyContinue

#endregion Declarations

#region Functions

function Write-EventLogEntry {
    # Create $message $Information and $ID parameters, and set help messages
    # All fields are set to mandatory, but ID, and Type are different parameter sets, and occupy the same position in the command.
    # logic for what the function requires: $Message AND ($Type OR $ID)
    param (
        [parameter(Mandatory,HelpMessage = 'Input text for the log entry', Position = 0)]
        [String]
        $Message,
        [parameter(Mandatory,ParameterSetName='Type',HelpMessage = 'Input type (severity level) for the log entry', Position = 1)]
        [string]
        [ValidateSet('Error', 'Warning', 'Information', 'SuccessAudit', 'FailureAudit')]
        $Type,
        [parameter(Mandatory,ParameterSetName='ID',HelpMessage = 'Input event ID for the log entry', Position = 1)]
        [int]
        [ValidatePattern("[1,2,3,5,6][0-9][0-9][0-9]")]
        $ID
    )

    # Specify final input parameters within $log_params variable
    $log_params = @{

        # LogTitle and EventSource are declared external from this function and are not expected to change for a given powershell process
        Logname   = $LogTitle
        Source    = $EventSource

        # Sets the EntryType to the parameter provided to the function, otherwise if an ID has been provided the event type will select itself based on the ID
        Entrytype = $(
            Switch ($ID){
                {1000..1999 -Contains $ID}{
                    Write-Output 'Error'
                }
                {2000..2999 -Contains $ID}{
                    Write-Output 'Warning'
                }
                {3000..3999 -Contains $ID}{
                    Write-Output 'Information'
                }
                {5000..5999 -Contains $ID}{
                    Write-Output 'SuccessAudit'
                }
                {6000..6999 -Contains $ID}{
                    Write-Output 'FailureAudit'
                }
                default{
                    Write-Output $type
                }
            }
        )
        # Sets the Event ID to the parameter provided to the function, otherwise if a type has been provided the ID will select a default code based on the event type
        EventID   = $(
            Switch ($type) {
                'Error'{
                    Write-Output -InputObject 1000
                }
                'Warning'{
                    Write-Output -InputObject 2000
                }
                'Information'{
                    Write-Output -InputObject 3000
                }
                'SuccessAudit'{
                    Write-Output -InputObject 5000
                }
                'FailureAudit'{
                    Write-Output -InputObject 6000
                }
                default{
                    Write-Output -InputObject $ID
                }
            }       
            
        )       
        Message   = $Message
    }
    #Commit logs from $log_params to Event Viewer
    Write-EventLog @log_params
}

Function Get-LoggedInUserProfile() {
# Tries to determine out who is logged in and returns their user profile path

    try {
       $loggedInUser = Gwmi -Class Win32_ComputerSystem | select username -ExpandProperty username
       $username = ($loggedInUser -split "\\")[1]
       #Identifying the correct path to the users profile folder - only selecting the first result in case there is a mess of profiles 
       #(which case you should do a clean up. As this script might not work in that case)
       $userProfile = Get-ChildItem (Join-Path -Path $env:SystemDrive -ChildPath 'Users') | Where-Object Name -Like "$username*" | select -First 1
       
    } catch [Exception] {
       throw Write-EventLogEntry -Message "Unable to find logged in users profile folder. User is not logged on to the primary session: $_" -Type Error
    }
    return $userProfile
}

Function Set-TeamsFWRule($ProfileObj) {
# Setting up the inbound firewall rule required for optimal Microsoft Teams screensharing within a LAN.
    Write-EventLogEntry -Message "Identified the current user as: $($ProfileObj.Name)" -Type Information
    $progPath = Join-Path -Path $ProfileObj.FullName -ChildPath "AppData\Local\Microsoft\Teams\Current\Teams.exe"
    if ((Test-Path $progPath) -or ($Force)) {
        if ($Force) {
            #Force parameter given - attempting to remove any potential pre-existing rules.  
            Write-EventLogEntry -Message "Force switch set: Purging any pre-existing rules." -Type Information  
            Get-NetFirewallApplicationFilter -Program $progPath -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
                
        }
        if (-not (Get-NetFirewallApplicationFilter -Program $progPath -ErrorAction SilentlyContinue)) {
            $ruleName = "Teams.exe for user $($ProfileObj.Name)"
            Write-EventLogEntry -Message "Adding Firewall rule: $ruleName" -type Information
            New-NetFirewallRule -DisplayName "$ruleName" -Direction Inbound -Profile Domain -Program $progPath -Action Allow -Protocol Any
            New-NetFirewallRule -DisplayName "$ruleName" -Direction Inbound -Profile Public,Private -Program $progPath -Action Block -Protocol Any

        } else {
            Write-EventLogEntry -Message "Rule already exists!" -Warning
        }
    } else {
      Throw Write-EventLogEntry -Message "Teams not found in $progPath - use the force parameter to override." -Type Error
    }       
}
#endregion Functions

#region Execution

#Add rule to WFAS
Try {
    Write-EventLogEntry -Message "Adding inbound Firewall rule for the currently logged in user." -Type Information
    #Combining the two function in order to set the Teams Firewall rule for the logged in user
    Set-TeamsFWRule -ProfileObj (Get-LoggedInUserProfile)
} catch [Exception] {
    #Something whent wrong and we should tell the log.
    Throw Write-EventLogEntry -Message "ERROR: $_" -Type Error
    exit 1
} Finally {
    Write-EventLogEntry -Message "Teams firewall rule generation has completed" -Type Information
}
#endregion Execution