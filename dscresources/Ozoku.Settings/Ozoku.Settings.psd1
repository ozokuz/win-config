@{
  RootModule           = 'Ozoku.Settings.psm1'
  ModuleVersion        = '0.0.1'
  GUID                 = '6b99eba3-cf7a-4859-a727-dbb7261863cf'
  Author               = 'Ozoku'
  CompanyName          = 'Ozoku'
  Copyright            = '(c) Ozoku. MIT License'
  Description          = 'This module contains DSC resources for configuring Windows settings.'
  PowerShellVersion    = '7.2'
  DscResourcesToExport = @('Explorer', 'System', 'PowerShellExecutionPolicy', 'RegistryTweaks')
}