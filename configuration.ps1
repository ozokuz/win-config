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

# Start
Write-Output "Starting Configuration"

# Registry Edits
Write-Output "Applying Registry Edits"
Set-ItemProperty -Path $global:ExplorerRegistryPath -Name 'HideIcons' -Value 1
Set-ItemProperty -Path $global:ExplorerRegistryPath -Name 'LaunchTo' -Value 1
if (-not (Test-Path -Path $global:StorageSenseRegistryPath)) {
  New-Item -Path $global:StorageSenseRegistryPath -Force
}
Set-ItemProperty -Path $global:StorageSenseRegistryPath -Name 'AllowStorageSenseGlobal' -Value 1
Set-ItemProperty -Path $global:FileSystemRegistryPath -Name 'LongPathsEnabled' -Value 1
Set-ItemProperty -Path $global:TimeZoneRegistryPath -Name 'RealTimeIsUniversal' -Value 1
Write-Output "Registry Edits Applied, Restarting Explorer"
taskkill /F /IM explorer.exe
Start-Process explorer.exe

# Remove Default Apps
Write-Output "Removing Default Apps"
$apps = @("Clipchamp", "549981C3F5F10", "BingNews", "BingWeather", "MicrosoftStickyNotes", "MicrosoftOfficeHub", "Todos", "WindowsFeedbackHub", "WindowsMaps", "WindowsSoundRecorder", "QuickAssist", "windowscommunicationsapps", "GetHelp", "Getstarted")
Get-AppxPackage -AllUsers | Where-Object { $apps -contains $_.Name } | Remove-AppxPackage -AllUsers
Write-Output "Removal Complete"

# Install Git
Write-Output "Installing Git"
if (-not (Test-Path -Path $env:ProgramFiles\Git)) {
  winget install -e Git.Git -s winget
}

# Clone win-config
Write-Output "Cloning config"
function ConfigCloned { Test-Path "$env:USERPROFILE\win-config" }
if (-not(ConfigCloned)) {
  RunRegular -taskName "CloneWinConfigRepo" -command "$env:ProgramFiles\Git\bin\git.exe" -argument "clone https://github.com/ozokuz/win-config $env:USERPROFILE\win-config --branch simplified" -checkComplete $function:ConfigCloned
}

# Set Location
Write-Output "Entering config"
Set-Location $env:USERPROFILE\win-config

# Create Folders
Write-Output "Creating Folders"
Get-Content .\values\folders.txt | ForEach-Object { New-Item -Path "$(Invoke-Expression $_)" -ItemType Directory }
Write-Output "Folders Created"

# Setup Quick Access Pins
Write-Output "Setting up Quick Access Pins"
$o = New-Object -ComObject shell.application
($o.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items()).InvokeVerb("unpinfromhome");
Get-Content .\values\quick-access.txt | ForEach-Object {
  $o.Namespace("$(Invoke-Expression $_)").Self.InvokeVerb("pintohome")
}
Write-Output "Quick Access Pins Set"

# Run OOSU
Write-Output "Running OOSU"
$oosuPath = "$env:USERPROFILE\Tools\OOSU"
Invoke-WebRequest "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile "$oosuPath\OOSU10.exe"
& "$oosuPath\OOSU10.exe" "$env:USERPROFILE\win-config\values\ooshutup10.cfg" /quiet
Write-Output "OOSU Complete"

# Install Scoop & Tools
Write-Output "Installing Scoop & Tools"
function ScoopInstalled { Test-Path "$env:USERPROFILE\scoop\.complete" -PathType Leaf }
RunRegular -taskName "ScoopSetup" -command "powershell.exe" -argument "$env:USERPROFILE\win-config\scripts\scoop.ps1" -checkComplete $function:ScoopInstalled
Write-Output "Scoop & Tools Installed"

# Install WSL
Write-Output "Installing WSL"
wsl.exe --install
Write-Output "WSL Installed"

# Install Apps
Write-Output "Installing Apps"
winget configure .\main.dsc.yml --accept-configuration-agreements
Write-Output "Apps Installed"

# Setup Config Symlinks
Write-Output "Setting up Config Symlinks"
Get-Content .\values\conf-paths.txt | ForEach-Object {
  $path = "$(Invoke-Expression $_)"
  $dir = Split-Path -Path $path -Parent
  if (-not (Test-Path -Path $dir)) {
    New-Item -Path $dir -ItemType Directory
  }
  $file = Split-Path -Path $path -Leaf
  SymbolicLink -source "$env:USERPROFILE\win-config\configs\$file" -path $path
}
Write-Output "Config Symlinks Set"

# Complete
Write-Output "Configuration Complete"
Read-Host -Prompt "Press Enter to exit"