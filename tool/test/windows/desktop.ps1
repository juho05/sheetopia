# Runs a .ps1 or .cmd file in the logged-on user's desktop session. SSH
# sessions can't show windows or see the desktop's windows, so everything
# that does goes through a scheduled task. Runs unelevated, like an app the
# user starts (drag and drop from Explorer into an elevated app is blocked).
#   desktop.ps1 -File <path> [-Wait [-TimeoutSec 120]] [-Name <task name>]
param([Parameter(Mandatory)][string]$File, [switch]$Wait, [int]$TimeoutSec = 120, [string]$Name)
$ErrorActionPreference = 'Stop'

$task = if ($Name) { "e2e-$Name" } else { 'e2e-' + [guid]::NewGuid().ToString('N').Substring(0, 8) }
$out = "C:\e2e\tmp\$task.out"
Remove-Item $out -ErrorAction SilentlyContinue
if ($File -like '*.cmd') {
  $command = "cmd.exe /c `"`"$File`" > `"$out`" 2>&1`""
} else {
  $command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command `"& '$File' *> '$out'`""
}
if (Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue) {
  Stop-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
  Unregister-ScheduledTask -TaskName $task -Confirm:$false
}
# A headless console host, so no console window flashes up and takes the
# focus (that would leave fullscreen, close menus).
$action = New-ScheduledTaskAction -Execute 'conhost.exe' -Argument "--headless $command"
# USERDOMAIN isn't the machine in SSH sessions.
$user = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances Parallel
Register-ScheduledTask -TaskName $task -Action $action -Principal $principal -Settings $settings | Out-Null
Start-ScheduledTask -TaskName $task
if (-not $Wait) { exit 0 }

# 267011: not run yet, 267009: running.
$deadline = (Get-Date).AddSeconds($TimeoutSec)
do {
  Start-Sleep -Milliseconds 200
  $result = (Get-ScheduledTaskInfo -TaskName $task).LastTaskResult
} while (($result -eq 267011 -or $result -eq 267009) -and (Get-Date) -lt $deadline)
if (Test-Path $out) { Get-Content $out }
Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction SilentlyContinue
if ($result -eq 267011 -or $result -eq 267009) {
  Write-Error "timed out after $TimeoutSec s"
  exit 1
}
exit $result
