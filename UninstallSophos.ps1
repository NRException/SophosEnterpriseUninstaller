[CmdletBinding()]
Param (

)

#region Funcs / Definitions
function Invoke-UninstallAncillaryService([string]$IdentifyingNumber) {

    Start-Process msiexec.exe -Wait -ArgumentList ('/X ' + $IdentifyingNumber + ' /qn REBOOT=ReallySuppress')
}

$SearchArray = @(
    @{Name = 'Sophos Patch Agent';Priority = 1},
    @{Name = 'Sophos Compliance Agent';Priority = 2},
    @{Name = 'Sophos Network Threat Protection';Priority = 3},
    @{Name = 'Sophos System Protection';Priority = 4},
    @{Name = 'Sophos Client Firewall';Priority = 5},
    @{Name = 'Sophos Anti-Virus';Priority = 6},
    @{Name = 'Sophos Exploit Prevention';Priority = 7},
    @{Name = 'Sophos Remote Management System';Priority = 8},
    @{Name = 'Sophos Management Communication System';Priority = 9},
    @{Name = 'Sophos AutoUpdate';Priority = 10},
    @{Name = 'Sophos Endpoint Defense';Priority = 11}
) | % { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }

$PriorityTable = @()
#endregion

Write-Verbose "Stopping SAUS..."
Stop-Service -Name 'Sophos AutoUpdate Service'

Write-Verbose "Getting all sophos packages (This may take a while)..."
#Get all packages that contain sophos.
$SophosPackages = Get-WmiObject Win32_Product | Where-Object {$_.Name -like "*sophos*"}

#Assign priority and order based on it. (Yes it's ugly, whatever...)
Write-Verbose "Re-ordering packages...`n"
foreach ($SPack in $SophosPackages){
    $SearchArray | % {
        if($_.Name -eq $SPack.Name) {
            $PriorityTable += @{
                Priority = $_.Priority
                Name = $SPack.Name
                Guid = $SPack.IdentifyingNumber
            } 
        }
    }
}
$PriorityTable = $PriorityTable | % { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru } | Sort-Object {$_.Priority}

Write-Verbose "Uninstall chain (execution may be halted until chain is complete):"
foreach ($UninstObject in $PriorityTable){
    Write-Verbos "Uninstalling" $UninstObject.Name "(" $UninstObject.Guid ") Priority:" $UninstObject.Priority
    Invoke-UninstallAncillaryService -IdentifyingNumber $UninstObject.Guid
}

Write-Verbose "Process complete. Returning..."
$SophObj = Get-WmiObject Win32_Product | Where-Object {$_.Name -like "*sophos*"}

if($SophObj.Count > 0) {
    Write-Output (New-Object PSObject -Property @{
        LeftoverPrograms=@{}
        Completed=$true
    })
} else {
    Write-Output (New-Object PSObject -Property @{
        LeftoverPrograms=$SophObj
        Completed=$false
    })
}
