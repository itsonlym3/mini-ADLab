Write-Host "Running second provision step"

# Additional provisioning commands
if (-Not (Test-Path -Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory
} else {
    Write-Host "DEBUG: Directory C:\Temp already exists."
}

# Re-enable automatic reboots if previously disabled
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -ErrorAction SilentlyContinue

Write-Host "DEBUG: Second provision step completed."

