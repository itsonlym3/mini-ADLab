Write-Host "Running first provision step"

# Disable automatic reboots for Windows Update
write-host "DEBUG: Disable automatic reboots for Windows Update..."
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -PropertyType DWord -Force

# Install AD DS and create a new forest/domain, this forces a reboot
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Create a new Active Directory forest
$SecureStringPassword = ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ("Administrator", $SecureStringPassword)

Install-ADDSForest `
    -DomainName "example.local" `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "7" `
    -DomainNetbiosName "EXAMPLE" `
    -ForestMode "7" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$true `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true `
    -SafeModeAdministratorPassword $SecureStringPassword

# Check if a restart is required
$restartPending = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
if ($restartPending) {
    Write-Host "DEBUG: A restart is required to complete the installation of AD DS."
} else {
    Write-Host "DEBUG: No restart required for AD DS installation."
}

# Install Chocolatey (package manager for Windows)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install a real software using Chocolatey, suppressing automatic reboot
choco install git -y --ignore-checksums --params "'/NoAutoReboot'"

# Disable automatic reboots for Windows Update
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -PropertyType DWord -Force

# Start the reboot handling script
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\MonitorAndHandleReboots.ps1`"" -WindowStyle Hidden

Write-Host "DEBUG: First provision step completed. VM will now reboot."

