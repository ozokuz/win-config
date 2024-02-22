$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

enum Ensure {
  Present
  Absent
}

$apps = @("Clipchamp", "549981C3F5F10", "BingNews", "BingWeather", "MicrosoftStickyNotes", "MicrosoftOfficeHub", "Todos", "WindowsFeedbackHub", "WindowsMaps", "WindowsSoundRecorder", "QuickAssist", "windowscommunicationsapps", "GetHelp", "Getstarted")

[DscResource()]
class RemoveDefaultApps {
  [DscProperty(Key)]
  [string] $SID

  [DscProperty(NotConfigurable)]
  [Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage[]] $AppsToRemove

  [RemoveDefaultApps] Get() {
    $this.AppsToRemove = Get-AppxPackage -AllUsers | Where-Object { $apps -contains $_.Name }

    return @{
      AppsToRemove = $this.AppsToRemove
    }
  }

  [bool] Test() {
    $currentState = $this.Get()

    return $currentState.AppsToRemove.Count -gt 0
  }

  [void] Set() {
    if (!$this.Test()) {
      return
    }

    $state = $this.Get()

    $state.AppsToRemove | Remove-AppxPackage -AllUsers
  }
}

[DscResource()]
class RunOOSU {
  [DscProperty(Key)]
  [string] $SID

  [DscProperty()]
  [string] $Folder = "$env:USERPROFILE\Tools"

  [DscProperty(NotConfigurable)]
  [bool] $Exists

  [RunOOSU] Get() {
    $this.Exists = Test-Path "$($this.Folder)\OOSU10.exe" -PathType Leaf

    return @{
      Exists = $this.Exists
    }
  }

  [bool] Test() {
    $currentState = $this.Get()

    return $currentState.Exists
  }

  [void] Set() {
    if (!$this.Test()) {
      if (-not (Test-Path "$($this.Folder)")) {
        mkdir "$($this.Folder)"
      }

      Invoke-WebRequest "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile "$($this.Folder)\OOSU10.exe"
      & "$($this.Folder)\OOSU10.exe" "$env:USERPROFILE\win-config\configs\ooshutup10.cfg" /quiet
    }
  }
}