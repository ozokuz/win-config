if (-not (Test-Path -Path $env:ProgramFiles\Git)) {
  winget install -e Git.Git
}

if (-not (Test-Path -Path $env:USERPROFILE\win-config)) {
  $action = New-ScheduledTaskAction -Execute "$env:ProgramFiles\Git\bin\git.exe" -Argument "clone https://github.com/ozokuz/win-config $env:USERPROFILE\win-config"
  Register-ScheduledTask -TaskName "CloneWinConfigRepo" -Action $action
  Start-ScheduledTask "CloneWinConfigRepo"
  $complete = $false
  do {
    $complete = Test-Path "$env:USERPROFILE\win-config"
    if (-not ($complete)) {
      Start-Sleep 1
    }
  } until ($complete)
  Unregister-ScheduledTask "CloneWinConfigRepo" -Confirm:$false
}

if (-not(Test-Path -Path $env:LOCALAPPDATA\Microsoft\WinGet\Configuration\Modules)) {
  mkdir -Force $env:LOCALAPPDATA\Microsoft\WinGet\Configuration\Modules
}

Get-ChildItem $env:USERPROFILE\win-config\dscresources | ForEach-Object {
  $module = $_.BaseName
  if (-not(Test-Path -Path $env:LOCALAPPDATA\Microsoft\WinGet\Configuration\Modules\$module)) {
    New-Item -Type SymbolicLink -Value $_.FullName -Path $env:LOCALAPPDATA\Microsoft\WinGet\Configuration\Modules\$module
  }
}

Set-Location $env:USERPROFILE\win-config
winget configure .\main.dsc.yml --accept-configuration-agreements