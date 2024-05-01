@{
  RootModule           = 'Ozoku.Startup.psm1'
  ModuleVersion        = '0.0.1'
  GUID                 = '61a87621-97bf-4a81-b5c4-bbbff94d7481'
  Author               = 'Ozoku'
  CompanyName          = 'Ozoku'
  Copyright            = '(c) Ozoku. MIT License'
  Description          = 'This module contains a DSC resource for configuring startup items.'
  PowerShellVersion    = '7.2'
  DscResourcesToExport = @('CreateStartupTask')
}