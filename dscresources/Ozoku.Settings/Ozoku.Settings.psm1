$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

enum EnableDisableFeature {
  KeepCurrentValue
  Enable
  Disable
}

enum ShowHideFeature {
  KeepCurrentValue
  Hide
  Show
}

enum LaunchTo {
  KeepCurrentValue
  ThisPC
  QuickAccess
}

$global:ExplorerRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\'
$global:StorageSenseRegistryPath = 'HKLM:\Software\Policies\Microsoft\Windows\StorageSense\'
$global:TimeZoneRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation\'
$global:FileSystemRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem\'

[DscResource()]
class Explorer {
  [DscProperty()] [LaunchTo] $LaunchTo = [LaunchTo]::KeepCurrentValue
  [DscProperty()] [ShowHideFeature] $DesktopIcons = [ShowHideFeature]::KeepCurrentValue

  [DscProperty()] [bool] $RestartExplorer = $false
  [DscProperty(Key)] [string] $SID

  hidden [string] $HideIcons = 'HideIcons'
  hidden [string] $LaunchTo = 'LaunchTo'

  [Explorer] Get() {
    $currentState = [Explorer]::new()

    # DesktopIcons
    if (-not(DoesRegistryKeyPropertyExist -Path $global:ExplorerRegistryPath -Name $currentState.HideIcons)) {
      $currentState.DesktopIcons = [ShowHideFeature]::Show
    }
    else {
      $value = [int](Get-ItemPropertyValue -Path $global:ExplorerRegistryPath -Name $currentState.HideIcons)
      $currentState.DesktopIcons = $value -eq 0 ? [ShowHideFeature]::Show : [ShowHideFeature]::Hide
    }

    # LaunchTo
    if (-not(DoesRegistryKeyPropertyExist -Path $global:ExplorerRegistryPath -Name $currentState.LaunchTo)) {
      $currentState.LaunchTo = [LaunchTo]::QuickAccess
    }
    else {
      $value = [int](Get-ItemPropertyValue -Path $global:ExplorerRegistryPath -Name $currentState.LaunchTo)
      $currentState.LaunchTo = $value -eq 0 ? [LaunchTo]::QuickAccess : [LaunchTo]::ThisPC
    }

    return $currentState
  }

  [bool] Test() {
    $currentState = $this.Get()

    if ($this.DesktopIcons -ne [ShowHideFeature]::KeepCurrentValue -and $this.DesktopIcons -ne $currentState.DesktopIcons) {
      return $false
    }

    if ($this.LaunchTo -ne [LaunchTo]::KeepCurrentValue -and $this.LaunchTo -ne $currentState.LaunchTo) {
      return $false
    }

    return $true
  }

  [void] Set() {
    if ($this.DesktopIcons -ne [ShowHideFeature]::KeepCurrentValue) {
      $value = $this.DesktopIcons -eq [ShowHideFeature]::Show ? 0 : 1
      Set-ItemProperty -Path $global:ExplorerRegistryPath -Name $this.HideIcons -Value $value
    }

    if ($this.LaunchTo -ne [LaunchTo]::KeepCurrentValue) {
      $value = $this.LaunchTo -eq [LaunchTo]::QuickAccess ? 0 : 1
      Set-ItemProperty -Path $global:ExplorerRegistryPath -Name $this.LaunchTo -Value $value
    }

    if ($this.RestartExplorer) {
      taskkill /F /IM explorer.exe
      Start-Process explorer.exe
    }
  }
}

[DscResource()]
class System {
  [DscProperty()] [EnableDisableFeature] $StorageSense = [EnableDisableFeature]::KeepCurrentValue

  [DscProperty(Key)] [string] $SID

  hidden [string] $AllowStorageSenseGlobal = 'AllowStorageSenseGlobal'

  [System] Get() {
    $currentState = [System]::new()

    if (-not(DoesRegistryKeyPropertyExist -Path $global:StorageSenseRegistryPath -Name $currentState.AllowStorageSenseGlobal)) {
      $currentState.StorageSense = [EnableDisableFeature]::Enable
    }
    else {
      $value = [int](Get-ItemPropertyValue -Path $global:StorageSenseRegistryPath -Name $currentState.AllowStorageSenseGlobal)
      $currentState.StorageSense = $value -eq 0 ? [EnableDisableFeature]::Enable : [EnableDisableFeature]::Disable
    }

    return $currentState
  }

  [bool] Test() {
    $currentState = $this.Get()

    return $this.StorageSense -eq $currentState.StorageSense
  }

  [void] Set() {
    $value = $this.StorageSense -eq [EnableDisableFeature]::Enable ? 0 : 1
    Set-ItemProperty -Path $global:StorageSenseRegistryPath -Name $this.AllowStorageSenseGlobal -Value $value
  }
}

[DscResource()]
class PowerShellExecutionPolicy {
  [DscProperty()] [string] $ExecutionPolicy = 'RemoteSigned'
  [DscProperty()] [string] $Scope = 'LocalMachine'
  [DscProperty(Key)] [string] $SID

  [PowerShellExecutionPolicy] Get() {
    $currentState = [PowerShellExecutionPolicy]::new()

    $policy = Get-ExecutionPolicy -Scope $currentState.Scope
    $currentState.ExecutionPolicy = $policy

    return $currentState
  }

  [bool] Test() {
    $currentState = $this.Get()

    return $this.ExecutionPolicy -eq $currentState.ExecutionPolicy
  }

  [void] Set() {
    Set-ExecutionPolicy -ExecutionPolicy $this.ExecutionPolicy -Scope $this.Scope
  }

}

[DscResource()]
class RegistryTweaks {
  [DscProperty()] [EnableDisableFeature] $LongPaths = [EnableDisableFeature]::KeepCurrentValue
  [DscProperty()] [EnableDisableFeature] $UTCTime = [EnableDisableFeature]::KeepCurrentValue

  [DscProperty(Key)] [string] $SID

  hidden [string] $LongPathsEnabled = 'LongPathsEnabled'
  hidden [string] $RealTimeIsUniversal = 'RealTimeIsUniversal'

  [RegistryTweaks] Get() {
    $currentState = [RegistryTweaks]::new()

    if (-not(DoesRegistryKeyPropertyExist -Path $global:FileSystemRegistryPath -Name $currentState.LongPathsEnabled)) {
      $currentState.LongPaths = [EnableDisableFeature]::Disable
    }
    else {
      $value = [int](Get-ItemPropertyValue -Path $global:FileSystemRegistryPath -Name $currentState.LongPathsEnabled)
      $currentState.LongPaths = $value -eq 0 ? [EnableDisableFeature]::Disable : [EnableDisableFeature]::Enable
    }

    if (-not(DoesRegistryKeyPropertyExist -Path $global:TimeZoneRegistryPath -Name $currentState.RealTimeIsUniversal)) {
      $currentState.UTCTime = [EnableDisableFeature]::Disable
    }
    else {
      $value = [int](Get-ItemPropertyValue -Path $global:TimeZoneRegistryPath -Name $currentState.RealTimeIsUniversal)
      $currentState.UTCTime = $value -eq 0 ? [EnableDisableFeature]::Disable : [EnableDisableFeature]::Enable
    }

    return $currentState
  }

  [bool] Test() {
    $currentState = $this.Get()

    if ($this.LongPaths -ne [EnableDisableFeature]::KeepCurrentValue -and $this.LongPaths -ne $currentState.LongPaths) {
      return $false
    }

    if ($this.UTCTime -ne [EnableDisableFeature]::KeepCurrentValue -and $this.UTCTime -ne $currentState.UTCTime) {
      return $false
    }

    return $true
  }

  [void] Set() {
    if ($this.LongPaths -ne [EnableDisableFeature]::KeepCurrentValue) {
      $value = $this.LongPaths -eq [EnableDisableFeature]::Enable ? 1 : 0
      Set-ItemProperty -Path $global:FileSystemRegistryPath -Name $this.LongPathsEnabled -Value $value
    }

    if ($this.UTCTime -ne [EnableDisableFeature]::KeepCurrentValue) {
      $value = $this.UTCTime -eq [EnableDisableFeature]::Enable ? 1 : 0
      Set-ItemProperty -Path $global:TimeZoneRegistryPath -Name $this.RealTimeIsUniversal -Value $value
    }
  }
}

function DoesRegistryKeyPropertyExist {
  param (
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$Name
  )

  # Get-ItemProperty will return $null if the registry key property does not exist.
  $itemProperty = Get-ItemProperty -Path $Path  -Name $Name -ErrorAction SilentlyContinue
  return $null -ne $itemProperty
}