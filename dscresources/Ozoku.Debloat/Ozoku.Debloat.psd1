@{
  RootModule           = "Ozoku.Debloat.psm1"
  ModuleVersion        = "0.0.1"
  GUID                 = "68b6f1d6-4e9d-43a9-9699-d8c6d0cd7d0c"
  Author               = "Ozoku"
  CompanyName          = "Ozoku"
  Copyright            = "(c) Ozoku. MIT License"
  Description          = "This module contains DSC resources for debloating Windows."
  PowerShellVersion    = "7.2"
  DscResourcesToExport = @("RemoveDefaultApps", "RunOOSU")
}