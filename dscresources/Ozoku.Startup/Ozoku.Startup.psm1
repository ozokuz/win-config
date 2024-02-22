$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

enum Ensure {
  Present
  Absent
}

enum StartupTaskType {
  User
  System
}

enum RunLevel {
  Highest
  Normal
}

[DscResource()]
class CreateStartupTask {
  [DscProperty(Key)]
  [string] $SID

  [DscProperty()]
  [string] $Name

  [DscProperty()]
  [string] $Command

  [DscProperty()]
  [RunLevel] $RunLevel = [RunLevel]::Normal

  [DscProperty()]
  [Ensure] $Ensure = [Ensure]::Present

  [DscProperty()]
  [StartupTaskType] $Type = [StartupTaskType]::System

  [DscProperty(NotConfigurable)]
  [bool] $Exists

  [DscProperty(NotConfigurable)]
  [CimInstance[]] $Task

  [CreateStartupTask] Get() {
    $this.Task = Get-ScheduledTask -TaskName $this.Name -ErrorAction SilentlyContinue

    return @{
      Name    = $this.Name
      Command = $this.Command
      RunAs   = $this.RunAs
      Ensure  = $this.Ensure
      Type    = $this.Type
      Exists  = [bool]$this.Task
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
        $action = New-ScheduledTaskAction -Execute $this.Command
        if ($this.Type -eq [StartupTaskType]::System) {
          $trigger = New-ScheduledTaskTrigger -AtStartup
        }
        else {
          $trigger = New-ScheduledTaskTrigger -AtLogon -User $env:USERNAME
        }

        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        $scheduledTask = New-ScheduledTask -Action $action -Trigger $trigger -TaskName $this.Name -RunLevel $this.RunAs -Settings $settings -ErrorAction SilentlyContinue

        if ($this.Type -eq [StartupTaskType]::System) {
          Register-ScheduledTask -InputObject $scheduledTask -TaskPath "\Microsoft\Windows\StartUp" -ErrorAction SilentlyContinue
        }
        else {
          Register-ScheduledTask -InputObject $scheduledTask -TaskPath "\Microsoft\Windows\StartUp" -User $env:USERNAME -ErrorAction SilentlyContinue
        }
      }
      else {
        Unregister-ScheduledTask -TaskName $this.Name -Confirm:$false -ErrorAction SilentlyContinue
      }
    }
  }
}