# The steps of the release workflow's build_windows_x86_64 job
# (.github/workflows/release.yml), run in the build VM over SSH. Keep them in
# sync with the workflow.
#   build.ps1 -Src <staged tree> -Flutter <sdk dir> -Out <dir>
param([Parameter(Mandatory)][string]$Src, [Parameter(Mandatory)][string]$Flutter, [Parameter(Mandatory)][string]$Out)
# Native tools write progress to stderr, which Stop would turn into errors.
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$env:Path = "$Flutter\bin;$env:ProgramFiles\Git\cmd;$env:Path"
$env:PUB_CACHE = 'C:\e2e\pub-cache'

function Step([string]$Name, [scriptblock]$Run) {
  Write-Output "== $Name"
  & $Run
  if ($LASTEXITCODE -ne 0) { Write-Output "$Name failed (exit $LASTEXITCODE)"; exit 1 }
}

Set-Location $Src
Step 'git config' { git config --global --add safe.directory '*' }
Step 'flutter config' { flutter --suppress-analytics config --no-analytics }
Step 'Dependencies' { flutter pub get }
Step 'Compile for Windows' { flutter build windows }
Step 'Build installer' { dart run inno_bundle --no-app --release }

New-Item -ItemType Directory -Force $Out | Out-Null
$installer = Get-ChildItem build\windows\x64\installer\Release\*-Installer.exe | Select-Object -First 1
if (-not $installer) { Write-Output 'no installer was built'; exit 1 }
Copy-Item $installer.FullName "$Out\installer.exe"

# The runtime must be at least as new as the MSVC that built the app.
foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
  Copy-Item "$env:WINDIR\System32\$dll" build/windows/x64/runner/Release/ -ErrorAction Stop
}
Compress-Archive -Path build/windows/x64/runner/Release/* -DestinationPath "$Out\Sheetopia.zip" -Force
Write-Output 'build done'
