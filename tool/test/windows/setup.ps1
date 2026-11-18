# Provisions the golden test VM over SSH (elevated). Safe to re-run.
#   setup.ps1 [-LoopMidi <loopMIDISetup.exe>]
param([string]$LoopMidi)
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

function Set-Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
  if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
  Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
}

# Never sleep, lock or show the screen saver while an agent drives it.
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
powercfg /hibernate off
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' NoLockScreen 1
Set-Reg 'HKCU:\Control Panel\Desktop' ScreenSaveActive '0' String
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' DisableLockWorkstation 1

# No updates, restarts or first-run screens getting in the way.
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' NoAutoUpdate 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' NoAutoRebootWithLoggedOnUsers 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' HideFirstRunExperience 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' DefaultBrowserSettingEnabled 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' StartupBoostEnabled 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' DisableWindowsConsumerFeatures 1
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' SubscribedContent-310093Enabled 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' ScoobeSystemSettingEnabled 0

# The test files differ by extension only (fake.pdf, notes.txt).
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' HideFileExt 0

# The clock is set by the harness (clock command), never synced.
Stop-Service w32time -ErrorAction SilentlyContinue
Set-Service w32time -StartupType Disabled

Add-MpPreference -ExclusionPath 'C:\e2e' -ErrorAction SilentlyContinue
foreach ($dir in 'C:\e2e\tmp', 'C:\e2e\midi', "$env:USERPROFILE\e2e", "$env:USERPROFILE\Downloads") {
  New-Item -ItemType Directory -Force $dir | Out-Null
}

if ($LoopMidi -and (Test-Path $LoopMidi)) {
  # The driver package is signed by the same publisher as the setup, trusting
  # it avoids the driver prompt that an unattended install can't answer.
  $cert = (Get-AuthenticodeSignature $LoopMidi).SignerCertificate
  if ($cert) {
    $store = New-Object Security.Cryptography.X509Certificates.X509Store('TrustedPublisher', 'LocalMachine')
    $store.Open('ReadWrite')
    $store.Add($cert)
    $store.Close()
  }
  $dll = "$env:WINDIR\System32\teVirtualMIDI64.dll"
  # A WiX Burn bundle, it ignores unknown switches and waits in its wizard.
  Write-Output 'loopMIDI setup'
  $p = Start-Process $LoopMidi -ArgumentList '/quiet', '/norestart' -PassThru
  if (-not $p.WaitForExit(300000)) { taskkill /F /T /PID $p.Id | Out-Null }
  # The midi.ps1 helper uses the driver, loopMIDI's window would only cover the app.
  Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -Name loopMIDI -ErrorAction SilentlyContinue
  if (Test-Path $dll) { Write-Output 'loopMIDI installed' } else { Write-Output 'warning: loopMIDI could not be installed, MIDI tests will be blocked' }
}
Write-Output 'golden VM provisioned'
