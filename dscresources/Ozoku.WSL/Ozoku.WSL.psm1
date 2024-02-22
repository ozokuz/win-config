$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

enum Ensure {
  Present
  Absent
}

[DscResource()]
class InstallWSL {
  [DscProperty(Key)]
  [string] $SID

  [DscProperty()]
  [Ensure] $Ensure = [Ensure]::Present

  [DscProperty()]
  [string] $Distribution = "Ubuntu"

  [DscProperty(NotConfigurable)]
  [string] $Output

  [InstallWSL] Get() {
    $this.Output = wsl.exe -l -q

    return @{
      Ensure       = $this.Ensure
      Distribution = $this.Distribution
      Output       = $this.Output
    }
  }

  [bool] Test() {
    $currentState = $this.Get()

    if ($this.Ensure -eq [Ensure]::Present) {
      return $currentState.Output -contains $currentState.Distribution
    }
    else {
      return $currentState.Output -notcontains $currentState.Distribution
    }
  }

  [void] Set() {
    if (!$this.Test()) {
      wsl.exe --install -d $this.Distribution
    }
  }
}