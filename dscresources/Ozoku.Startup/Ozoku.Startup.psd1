@{
  RootModule           = 'Ozoku.Startup.psm1'
  ModuleVersion        = '0.0.1'
  GUID                 = 'f39b2776-4a70-4b72-b5ca-cea81311af1e'
  Author               = 'Ozoku'
  CompanyName          = 'Ozoku'
  Copyright            = '(c) Ozoku. MIT License'
  Description          = 'This module contains a DSC resource for configuring startup items.'
  PowerShellVersion    = '7.2'
  DscResourcesToExport = @('CreateStartupTask')
}