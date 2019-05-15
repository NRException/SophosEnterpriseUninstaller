[CmdletBinding()]
Param (
    [Boolean]$Testing=$false
)

function Invoke-UninstallAncillaryService([string]$IdentifyingNumber) {
    if($Testing -eq $false) {
        Start-Process msiexec.exe -Wait -ArgumentList ('/X ' + $IdentifyingNumber + ' /qn REBOOT=ReallySuppress')
    }
}

function Write-VerboseRegKey {
    Param (
        [String]$Path,
        [String]$Key,
        [Int]$Value
    )
    Write-Verbose ("Write Key: {0} [{1}] --> {2}" -f $Path, $Key, $Value)
    if($Testing -eq $false)
    {
        try {
            Set-ItemProperty -Path $Path -Name $Key -Value $Value -ErrorAction SilentlyContinue
            Write-Verbose "`tOK"
        } catch [System.Management.Automation.ItemNotFoundException] {
            New-ItemProperty -Path $Path -Name $Key -Value $Value -ErrorAction SilentlyContinue
            Write-Verbose "`tOK (New Item)"
        } catch {
            Write-Verbose "`tFAIL (Total failure to change reg state)"
        }
    }
}

$logPath = "C:\Invoke-UninstallSophos.log"

#Lets check to see if we have administrator rights
if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Verbose "Required elevation is good... Lets go!"
  } else {
    throw "Not elevated. Please run this as admin in powershell! Exiting..."
    exit
}

Start-Transcript -Path $logPath

#Could do this a more efficient way, but this is PSv2 compatible.
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

if($Testing -eq $false) {
    Write-Verbose "Stopping services..."
    Write-Verbose "`tSophos Auto Update Service"
    Stop-Service -Name 'Sophos AutoUpdate Service' -ErrorAction SilentlyContinue
    Write-Verbose "`tSophos Anti-Virus"
    Stop-Service -Name 'Sophos Anti-Virus' -ErrorAction SilentlyContinue
    Write-Verbose "`tSetting Sophos Anti-Virus startup type to disabled..."
    Set-Service "Sophos Anti-Virus" -StartupType Disabled
}

#Recommended Sophos TP keys can be found here: https://community.sophos.com/kb/en-us/124377
Write-Verbose "Flipping Registry Keys to disable SED Tamper protection..."
Write-VerboseRegKey -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Sophos Endpoint Defense\TamperProtection\Config" -Key "SavEnabled" -Value 0 
Write-VerboseRegKey -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Sophos Endpoint Defense\TamperProtection\Config" -Key "SEDEnabled" -Value 0
Write-VerboseRegKey -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Sophos MCS Agent" -Key "Start" -Value 4
Write-VerboseRegKey -Path "HKLM:\SOFTWARE\WOW6432Node\Sophos\SavService\TamperProtection" -Key "Enabled" -Value 0
Write-VerboseRegKey -Path "HKLM:\SOFTWARE\Sophos\SAVService\TamperProtection" -Key "Enabled" -Value 0
Write-VerboseRegKey -Path "HKLM:\SOFTWARE\WOW6432Node\Sophos\SAVService\TamperProtection" -Key "Enabled" -Value 0

Write-Verbose "Getting all sophos packages (This may take a while)..."
#Get all packages that contain sophos.
$SophosPackages = Get-WmiObject Win32_Product | Where-Object {$_.Name -like "*sophos*"}

#Assign priority and order based on it. (Yes it's ugly and produces duplicates but whatever...)
$PriorityTable = @()
Write-Verbose "Sorting packages..."
foreach ($SPack in $SophosPackages){
    $SearchArray | ForEach-Object {
        if($_.Name -eq $SPack.Name) {
            $PriorityTable += New-Object PSObject -Property @{
                Priority = $_.Priority
                Name = $SPack.Name
                Guid = $SPack.IdentifyingNumber}
        }
        else
        {
            #If we cant find it in our search array, just assign it a lower priority.
            #This should stop duplicates... MAYBE? :)
            if($null -eq ($PriorityTable | Where-Object {$_.Guid -eq $SPack.IdentifyingNumber})) {
            $PriorityTable += New-Object PSObject -Property @{
                Priority = ($PriorityTable.Count + 1)
                Name = $SPack.Name
                Guid = $SPack.IdentifyingNumber
            }
            }
        }
    }
}
$PriorityTable = $PriorityTable | Sort-Object {$_.Priority}

Write-Verbose ([String]"All packages totalled, TOTAL PACKAGES: {0}" -f ($PriorityTable.Count))

#Verbose logging of uninstall chain.
Write-Verbose "Uninstall chain... Execution may be halted until chain is complete."
foreach ($UninstObject in $PriorityTable) {
    [String]$outputString = "Invoking Uninstall {0} ({1}) With Priority of {2}" -f ($UninstObject.Name, $UninstObject.Guid, $UninstObject.Priority)
    Write-Verbose $outputString
    Write-Progress -Activity "Uninstalling Sophos Packages" -Status ($outputString) -PercentComplete ($UninstObject.Priority / $PriorityTable.Count * 100)
    Invoke-UninstallAncillaryService -IdentifyingNumber $UninstObject.Guid
}

#Re-count left-over installed packages.
Write-Verbose "Uninstall chain complete!"
$SophObj = Get-WmiObject Win32_Product | Where-Object {$_.Name -like "*sophos*"}

#Aaaaand return!
if($SophObj.Count -gt 0) {
    Write-Output (New-Object PSObject -Property @{
        LeftoverPrograms=@{}
        Completed=$true
    })
    Stop-Transcript
    Set-ExecutionPolicy -ExecutionPolicy Default
    return 1
} else {
    Write-Output (New-Object PSObject -Property @{
        LeftoverPrograms=$SophObj | Select-Object -ExpandProperty Name
        Completed=$false
    })
    Stop-Transcript
    Set-ExecutionPolicy -ExecutionPolicy Default
    return 10
}
