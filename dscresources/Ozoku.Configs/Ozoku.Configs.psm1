$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

enum Ensure {
  Present
  Absent
}

[DscResource()]
class Symlink {
  [DscProperty(Key)]
  [string] $SID

  [DscProperty()]
  [string] $Path

  [DscProperty()]
  [string] $Source

  [DscProperty()]
  [Ensure] $Ensure = [Ensure]::Present

  [DscProperty(NotConfigurable)]
  [bool] $Exists

  [Symlink] Get() {
    $this.Exists = Test-Path -Path $this.Path -PathType Leaf

    return @{
      Path   = $this.Path
      Source = $this.Source
      Ensure = $this.Ensure
      Exists = $this.Exists
    }
  }

  [bool] Test() {
    $currentState = $this.Get()
    if ($this.Ensure -eq [Ensure]::Present) {
      return $currentState.Exists
    }
    else {
      return $currentState.Exists -eq $false
    }
  }

  [void] Set() {
    if (!$this.Test()) {
      if ($this.Ensure -eq [Ensure]::Present) {
        New-Item -Type SymbolicLink -Value $this.Source -Path $this.Path
      }
      else {
        Remove-Item -Path $this.Path -Force
      }
    }
  }
}
