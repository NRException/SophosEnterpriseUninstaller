[CmdletBinding()]
Param (
    [Boolean]$ProvideLoggingFile
)

#region Funcs / Definitions
function Invoke-UninstallAncillaryService([string]$IdentifyingNumber) {

    Start-Process msiexec.exe -Wait -ArgumentList ('/X ' + $IdentifyingNumber + ' /qn REBOOT=ReallySuppress')
}
function Write-Log([string]$logEntryString) {
    if($ProvideLoggingFile=$TRUE) {
        Add-Content -Path $logPath -Value $logEntryString
    }
}
$logPath = "C:\Invoke-UninstallSophos.log"

$SearchArray = @()
$SearchArray += New-Object PSObject -Property @{Name = 'Sophos Patch Agent';Priority = 1}
$SearchArray += New-Object PSObject -Property @{Name = 'Sophos Compliance Agent';Priority = 2}
$SearchArray += New-Object PSObject -Property @{Name = 'Sophos Network Threat Protection';Priority = 3}
$SearchArray += New-Object PSObject -Property @{Name = 'Sophos System Protection';Priority = 4}
$SearchArray += New-Object PSObject -Property @{Name = 'Sophos Client Firewall';Priority = 5}
$SearchArray += New-Object PSObject -Property @{Name = 'Sophos Anti-Virus';Priority = 6}
$SearchArray += New-Object PSObject -Property @{Name = 'Sophos Exploit Prevention';Priority = 7}
$SearchArray += New-Object PSObject -Property @{Name = 'Sophos Remote Management System';Priority = 8}
$SearchArray += New-Object PSObject -Property @{Name = 'Sophos Management Communication System';Priority = 9}
$SearchArray += New-Object PSObject -Property @{Name = 'Sophos AutoUpdate';Priority = 10}
$SearchArray += New-Object PSObject -Property @{Name = 'Sophos Endpoint Defense';Priority = 11}
#endregion

Write-Verbose "Stopping services..."
Write-Verbose "`tSophos Auto Update Service"
Stop-Service -Name 'Sophos AutoUpdate Service' -ErrorAction SilentlyContinue
Write-Verbose "`tSophos Anti-Virus"
Stop-Service -Name 'Sophos Anti-Virus' -ErrorAction SilentlyContinue

Write-Verbose "Getting all sophos packages (This may take a while)..."
#Get all packages that contain sophos.
$SophosPackages = Get-WmiObject Win32_Product | Where-Object {$_.Name -like "*sophos*"}

#Assign priority and order based on it. (Yes it's ugly, whatever...)
$PriorityTable = @()
Write-Verbose "Re-ordering packages..."
foreach ($SPack in $SophosPackages){
    $SearchArray | % {
        if($_.Name -eq $SPack.Name) {
            $PriorityTable += New-Object PSObject -Property @{
                Priority = $_.Priority
                Name = $SPack.Name
                Guid = $SPack.IdentifyingNumber}
        }
        else
        {
            #If we cant find it in our search array, just assign it a lower priority.
            $PriorityTable += New-Object PSObject -Property @{
                Priority = ($PriorityTable.Count + 1)
                Name = $SPack.Name
                Guid = $SPack.IdentifyingNumber
            }
        }
    }
}
$PriorityTable = $PriorityTable | Sort-Object {$_.Priority}

Write-Verbose ([String]"All packages totalled, TOTAL PACKAGES: {0}" -f ($PriorityTable.Count))

#Verbose logging of uninstall chain.
Write-Verbose "Uninstall chain... Execution may be halted until chain is complete."
Write-Log "Uninstall chain... Execution may be halted until chain is complete."
foreach ($UninstObject in $PriorityTable) {
    [String]$outputString = "Invoking Uninstall {0} ({1}) With Priority of {2}" -f ($UninstObject.Name, $UninstObject.Guid, $UninstObject.Priority)
    Write-Verbose $outputString
    Write-Log $outputString
    Write-Progress -Activity "Uninstalling Sophos Packages" -Status ($outputString) -PercentComplete ($UninstObject.Priority / $PriorityTable.Count * 100)
    Invoke-UninstallAncillaryService -IdentifyingNumber $UninstObject.Guid
}

#Re-count left-over installed packages.
Write-Verbose "Uninstall chain complete!"
$SophObj = Get-WmiObject Win32_Product | Where-Object {$_.Name -like "*sophos*"}

#Aaaaand return!
if($SophObj.Count > 0) {
    Write-Output (New-Object PSObject -Property @{
        LeftoverPrograms=@{}
        Completed=$true
    })
   Write-Log ("Script returning {0}" -f (1))
   return 1
} else {
    Write-Output (New-Object PSObject -Property @{
        LeftoverPrograms=$SophObj | select -ExpandProperty Name
        Completed=$false
    })
    Write-Log ("Script returning {0}" -f (10))
    return 10
}
