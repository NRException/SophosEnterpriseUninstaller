#region Definitions
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

write-host "Stopping SAUS..."
Stop-Service -Name 'Sophos AutoUpdate Service'

write-host "Getting all sophos packages (This may take a while)..."
#Get all packages that contain sophos.
$SophosPackages = Get-WmiObject Win32_Product | Where-Object {$_.Name -like "*sophos*"} | Select IdentifyingNumber, Name

#Assign priority and order based on it. (Yes it's ugly, whatever...)
write-host "Re-ordering packages...`n"
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

Write-Host "Uninstall chain (execution may be halted until chain is complete):" -ForegroundColor Green
foreach ($UninstObject in $PriorityTable){
    Write-Host "Uninstalling" $UninstObject.Name "(" $UninstObject.Guid ") Priority:" $UninstObject.Priority
    Invoke-UninstallAncillaryService -IdentifyingNumber $UninstObject.Guid
}

Write-Host "Process complete. Here is a list of potential left-over packages:" -ForegroundColor Green
Get-WmiObject Win32_Product | Where-Object {$_.Name -like "*sophos*"} | Select IdentifyingNumber, Name

Write-Host "Reboot in countdown now..."