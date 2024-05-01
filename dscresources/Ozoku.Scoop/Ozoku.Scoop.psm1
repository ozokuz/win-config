enum Ensure {
  Present
  Absent
}

[DscResource()]
class InstallScoop {
  [DscProperty(Key)] [string] $SID
  [DscProperty()] [Ensure] $Ensure = [Ensure]::Present

  [DscProperty(NotConfigurable)] [bool] $IsInstalled

  [InstallScoop] Get() {
    $currentState = [InstallScoop]::new()

    $currentState.IsInstalled = Test-Path -Path "$env:USERPROFILE\scoop"

    return $currentState
  }

  [bool] Test() {
    $currentState = $this.Get()

    if ($this.Ensure -eq [Ensure]::Present -and -not($currentState.IsInstalled)) {
      return $false
    }

    if ($this.Ensure -eq [Ensure]::Absent -and $currentState.IsInstalled) {
      return $false
    }

    return $true
  }

  [void] Set() {
    if (!($this.IsInstalled) -and $this.Ensure -eq [Ensure]::Present) {
      $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "$env:USERPROFILE\win-config\scripts\scoop.ps1"
      Register-ScheduledTask -TaskName "SetupScoop" -Action $action
      Start-ScheduledTask "SetupScoop"
      $scoopComplete = $false
      do {
        $scoopComplete = Test-Path "$env:USERPROFILE\scoop"
        if (-not ($scoopComplete)) {
          Start-Sleep 1
        }
      } until ($scoopComplete)
      Unregister-ScheduledTask "SetupScoop" -Confirm:$false
    }
    elseif ($this.IsInstalled -and $this.Ensure -eq [Ensure]::Absent) {
      Remove-Item -Path "$env:USERPROFILE\scoop" -Recurse -Force
    }
  }
}

[DscResource()]
class ScoopBucket {
  [DscProperty(Key)] [string] $SID
  [DscProperty()] [string] $Name
  [DscProperty()] [Ensure] $Ensure = [Ensure]::Present

  [DscProperty(NotConfigurable)] [bool] $IsInstalled

  [ScoopBucket] Get() {
    $currentState = [ScoopBucket]::new()

    $currentState.IsInstalled = Test-Path -Path "$env:USERPROFILE\scoop\buckets\$($this.Name)"

    return $currentState
  }

  [bool] Test() {
    $currentState = $this.Get()

    if ($this.Ensure -eq [Ensure]::Present -and -not($currentState.IsInstalled)) {
      return $false
    }

    if ($this.Ensure -eq [Ensure]::Absent -and $currentState.IsInstalled) {
      return $false
    }

    return $true
  }

  [void] Set() {
    if (!($this.IsInstalled) -and $this.Ensure -eq [Ensure]::Present) {
      scoop bucket add $this.Name
    }
    elseif ($this.IsInstalled -and $this.Ensure -eq [Ensure]::Absent) {
      scoop bucket rm $this.Name
    }
  }
}

[DscResource()]
class ScoopApp {
  [DscProperty(Key)] [string] $SID
  [DscProperty()] [string] $Name
  [DscProperty()] [Ensure] $Ensure = [Ensure]::Present

  [DscProperty(NotConfigurable)] [bool] $IsInstalled

  [ScoopApp] Get() {
    $currentState = [ScoopApp]::new()

    $currentState.IsInstalled = Test-Path -Path "$env:USERPROFILE\scoop\apps\$($this.Name)"

    return $currentState
  }

  [bool] Test() {
    $currentState = $this.Get()

    if ($this.Ensure -eq [Ensure]::Present -and -not($currentState.IsInstalled)) {
      return $false
    }

    if ($this.Ensure -eq [Ensure]::Absent -and $currentState.IsInstalled) {
      return $false
    }

    return $true
  }

  [void] Set() {
    if (!($this.IsInstalled) -and $this.Ensure -eq [Ensure]::Present) {
      scoop install $this.Name
    }
    elseif ($this.IsInstalled -and $this.Ensure -eq [Ensure]::Absent) {
      scoop uninstall $this.Name
    }
  }
}