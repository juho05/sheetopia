# Turns a copy of the golden test VM into the golden build VM: the tools the
# release workflow's windows-latest runner has (MSVC, Git, Inno Setup).
param([Parameter(Mandatory)][string]$VsUrl, [Parameter(Mandatory)][string]$GitUrl, [Parameter(Mandatory)][string]$InnoUrl)
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$dl = 'C:\e2e\tmp'

function Install([string]$Name, [string]$Check, [string]$Url, [string]$File, [string[]]$Arguments, [int[]]$Ok = @(0)) {
  if (Test-Path $Check) { Write-Output "$Name is installed"; return }
  Write-Output "installing $Name"
  Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile "$dl\$File" -ErrorAction Stop
  $p = Start-Process "$dl\$File" -ArgumentList $Arguments -Wait -PassThru
  Remove-Item "$dl\$File" -ErrorAction SilentlyContinue
  if ($Ok -notcontains $p.ExitCode) { throw "$Name setup failed with exit code $($p.ExitCode)" }
}

# ATL is needed by flutter_secure_storage_windows, the runners have it.
$vs = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools"
$vsArgs = @(
  '--quiet', '--wait', '--norestart', '--nocache',
  '--add', 'Microsoft.VisualStudio.Workload.VCTools', '--add', 'Microsoft.VisualStudio.Component.VC.ATL', '--includeRecommended'
)
if (Test-Path "$vs\VC\Tools\MSVC") { $vsArgs = @('modify', '--installPath', "`"$vs`"") + $vsArgs }
Install 'Visual Studio Build Tools' "$vs\VC\Tools\MSVC\*\atlmfc\include\atlstr.h" $VsUrl 'vs_BuildTools.exe' $vsArgs @(0, 3010)
Install 'Git' "$env:ProgramFiles\Git\cmd\git.exe" $GitUrl 'git-setup.exe' @('/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-', '/SUPPRESSMSGBOXES')
Install 'Inno Setup' "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe" $InnoUrl 'innosetup.exe' @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-', '/ALLUSERS')

# Flutter needs symlinks for plugins (Developer Mode).
New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name AllowDevelopmentWithoutDevLicense -Value 1 -Type DWord
& "$env:ProgramFiles\Git\cmd\git.exe" config --system core.longpaths true
Write-Output 'build tools installed'
