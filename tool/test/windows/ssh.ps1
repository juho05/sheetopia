# OpenSSH server with the harness key, the only setup done during the
# unattended install. Everything else runs over SSH (windows_vm.sh golden).
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) {
  Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
}
if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) {
  # Without Windows Update the capability can't be installed.
  $zip = "$env:TEMP\OpenSSH-Win64.zip"
  Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/download/OpenSSH-Win64.zip' -OutFile $zip
  Expand-Archive $zip -DestinationPath $env:ProgramFiles -Force
  & "$env:ProgramFiles\OpenSSH-Win64\install-sshd.ps1"
}
Set-Service sshd -StartupType Automatic
Start-Service sshd
if (-not (Get-NetFirewallRule -Name 'e2e-sshd' -ErrorAction SilentlyContinue)) {
  New-NetFirewallRule -Name 'e2e-sshd' -DisplayName 'OpenSSH Server (E2E)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
}

# Keys of administrators are only read from this file, which must be
# writable by Administrators and SYSTEM only.
$keys = "$env:ProgramData\ssh\administrators_authorized_keys"
Copy-Item C:\OEM\e2e_key.pub $keys -Force
icacls $keys /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null
Restart-Service sshd
