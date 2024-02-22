@{
  RootModule           = "Ozoku.Debloat.psm1"
  ModuleVersion        = "0.0.1"
  GUID                 = ""
  Author               = "Ozoku"
  CompanyName          = "Ozoku"
  Copyright            = "(c) Ozoku. MIT License"
  Description          = "This module contains DSC resources for debloating Windows."
  PowerShellVersion    = "7.2"
  DscResourcesToExport = @("RemoveDefaultApps", "RunOOSU")
}