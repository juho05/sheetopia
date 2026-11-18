# A virtual MIDI device through loopMIDI's teVirtualMIDI driver, present as
# long as this runs. Sends the hex bytes of every *.msg file put into
# C:\e2e\midi (windows_vm.sh midi send), stops when C:\e2e\midi\stop appears.
#   midi.ps1 [-Name 'E2E Pedal']
param([string]$Name = 'E2E Pedal')
$ErrorActionPreference = 'Stop'

$dll = @("$env:WINDIR\System32\teVirtualMIDI64.dll") +
  @(Get-ChildItem "${env:ProgramFiles(x86)}\Tobias Erichsen", "$env:ProgramFiles\Tobias Erichsen" -Recurse -Filter teVirtualMIDI64.dll -ErrorAction SilentlyContinue | ForEach-Object FullName) |
  Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $dll) { throw 'teVirtualMIDI64.dll not found, loopMIDI is not installed' }

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class E2eVirtualMidi {
  [DllImport("kernel32", CharSet = CharSet.Unicode, SetLastError = true)]
  public static extern IntPtr LoadLibrary(string path);
  [DllImport("teVirtualMIDI64.dll", CharSet = CharSet.Unicode, SetLastError = true)]
  public static extern IntPtr virtualMIDICreatePortEx2(string name, IntPtr callback, IntPtr instance, uint maxSysexLength, uint flags);
  [DllImport("teVirtualMIDI64.dll", SetLastError = true)]
  public static extern bool virtualMIDISendData(IntPtr port, byte[] data, uint length);
  [DllImport("teVirtualMIDI64.dll")]
  public static extern void virtualMIDIClosePort(IntPtr port);
}
'@
[void][E2eVirtualMidi]::LoadLibrary($dll)
# TE_VM_FLAGS_PARSE_RX | TE_VM_FLAGS_PARSE_TX
$port = [E2eVirtualMidi]::virtualMIDICreatePortEx2($Name, [IntPtr]::Zero, [IntPtr]::Zero, 65535, 3)
if ($port -eq [IntPtr]::Zero) { throw "creating the MIDI port failed (error $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))" }

$queue = 'C:\e2e\midi'
New-Item -ItemType Directory -Force $queue | Out-Null
Remove-Item "$queue\stop" -ErrorAction SilentlyContinue
Set-Content "$queue\port" $Name
try {
  while (-not (Test-Path "$queue\stop")) {
    foreach ($msg in Get-ChildItem $queue -Filter *.msg | Sort-Object Name) {
      $bytes = [byte[]]@((Get-Content $msg.FullName -Raw).Trim() -split '\s+' | ForEach-Object { [Convert]::ToByte($_, 16) })
      if (-not [E2eVirtualMidi]::virtualMIDISendData($port, $bytes, $bytes.Length)) {
        Write-Output "sending $($bytes.Length) bytes failed"
      }
      Remove-Item $msg.FullName
    }
    Start-Sleep -Milliseconds 50
  }
} finally {
  [E2eVirtualMidi]::virtualMIDIClosePort($port)
  Remove-Item "$queue\port", "$queue\stop" -ErrorAction SilentlyContinue
}
