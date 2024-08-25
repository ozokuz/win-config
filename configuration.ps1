# Constants
$global:ExplorerRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\'
$global:StorageSenseRegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\StorageSense\'
$global:TimeZoneRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation\'
$global:FileSystemRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem\'
$global:QuickAccessLocation = "shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}"

# Functions
function RunRegular ([string]$taskName, [string]$command, [string]$argument, [ScriptBlock]$checkComplete) {
  $action = New-ScheduledTaskAction -Execute $command -Argument $argument
  Register-ScheduledTask -TaskName $taskName -Action $action
  Start-ScheduledTask $taskName
  $complete = $false
  do {
    $complete = (&$checkComplete)
    if (-not ($complete)) {
      Start-Sleep 1
    }
  } until ($complete)
  Unregister-ScheduledTask $taskName -Confirm:$false
}

function SymbolicLink($source, $path) {
  New-Item -Type SymbolicLink -Value $source -Path $path
}

# Registry Edits
Set-ItemProperty -Path $global:ExplorerRegistryPath -Name 'HideIcons' -Value 1
Set-ItemProperty -Path $global:ExplorerRegistryPath -Name 'LaunchTo' -Value 1
Set-ItemProperty -Path $global:StorageSenseRegistryPath -Name 'AllowStorageSenseGlobal' -Value 1
Set-ItemProperty -Path $global:FileSystemRegistryPath -Name 'LongPathsEnabled' -Value 1
Set-ItemProperty -Path $global:TimeZoneRegistryPath -Name 'RealTimeIsUniversal' -Value 1
taskkill /F /IM explorer.exe
Start-Process explorer.exe

# Remove Default Apps
$apps = @("Clipchamp", "549981C3F5F10", "BingNews", "BingWeather", "MicrosoftStickyNotes", "MicrosoftOfficeHub", "Todos", "WindowsFeedbackHub", "WindowsMaps", "WindowsSoundRecorder", "QuickAssist", "windowscommunicationsapps", "GetHelp", "Getstarted")
Get-AppxPackage -AllUsers | Where-Object { $apps -contains $_.Name } | Remove-AppxPackage -AllUsers

# Install Git
if (-not (Test-Path -Path $env:ProgramFiles\Git)) {
  winget install -e Git.Git
}

# Clone win-config
function ConfigCloned { Test-Path "$env:USERPROFILE\win-config" }
if (-not(ConfigCloned)) {
  RunRegular -taskName "CloneWinConfigRepo" -command "$env:ProgramFiles\Git\bin\git.exe" -argument "clone https://github.com/ozokuz/win-config $env:USERPROFILE\win-config" -checkComplete $function:ConfigCloned
}

# Set Location
Set-Location $env:USERPROFILE\win-config

# Create Folders
Get-Content .\values\folders.txt | ForEach-Object { New-Item -Path "$(Invoke-Expression $_)" -ItemType Directory }

# Setup Quick Access Pins
$o = New-Object -ComObject shell.application
($o.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items()).InvokeVerb("unpinfromhome");
Get-Content .\values\quick-access.txt | ForEach-Object {
  $o.Namespace("$(Invoke-Expression $_)").Self.InvokeVerb("pintohome")
}

# Run OOSU
oosuPath = "$env:USERPROFILE\Tools\OOSU"
Invoke-WebRequest "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile "$oosuPath\OOSU10.exe"
& "$oosuPath\OOSU10.exe" "$env:USERPROFILE\win-config\values\ooshutup10.cfg" /quiet

# Install Scoop & Tools
function ScoopInstalled { Test-Path "$env:USERPROFILE\scoop\.complete" -PathType Leaf }
RunRegular -taskName "ScoopSetup" -command "powershell.exe" -argument "$env:USERPROFILE\win-config\scripts\scoop.ps1" -checkComplete $function:ScoopInstalled

# Install WSL
wsl.exe --install

# Install Apps
winget configure .\main.dsc.yml --accept-configuration-agreements

# Setup Config Symlinks
Get-Content .\values\conf-paths.txt | ForEach-Object {
  $path = "$(Invoke-Expression $_)"
  $dir = Split-Path -Path $path -Parent
  if (-not (Test-Path -Path $dir)) {
    New-Item -Path $dir -ItemType Directory
  }
  $file = Split-Path -Path $path -Leaf
  SymbolicLink -source "$env:USERPROFILE\win-config\configs\$file" -path $path
}