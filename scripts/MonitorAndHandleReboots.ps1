# Function to check for pending reboots
function Test-PendingReboot {
    $reboot = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' -ErrorAction SilentlyContinue
    if ($reboot) { return $true }
    $reboot = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue
    if ($reboot) { return $true }
    $reboot = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue
    if ($reboot) { return $true }
    return $false
}

# Loop to monitor for pending reboots
while ($true) {
    if (Test-PendingReboot) {
        Write-Host "DEBUG: Pending reboot detected. Handling reboot request."
        # Logic to handle reboot, e.g., notify user, delay, or log
        # For example, cancel the reboot and log the event
        shutdown.exe /a
        Add-Content -Path "C:\RebootLog.txt" -Value "$(Get-Date): Reboot request intercepted and cancelled."
    }
    Start-Sleep -Seconds 15  # Check every 15 seconds
}

