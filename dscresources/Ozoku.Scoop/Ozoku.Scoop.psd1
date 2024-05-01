@{
  RootModule           = 'Ozoku.Scoop.psm1'
  ModuleVersion        = '0.0.1'
  GUID                 = '89332cfd-0ecf-4c46-9a52-06016ae54c58'
  Author               = 'Ozoku'
  CompanyName          = 'Ozoku'
  Copyright            = '(c) Ozoku. MIT License'
  Description          = 'This module contains DSC resources for installing and configuring Scoop and its apps.'
  PowerShellVersion    = '7.2'
  DscResourcesToExport = @('InstallScoop', 'ScoopBucket', 'ScoopApp')
}