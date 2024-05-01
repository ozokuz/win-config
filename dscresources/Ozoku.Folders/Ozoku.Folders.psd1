@{
  RootModule           = 'Ozoku.Folders.psm1'
  ModuleVersion        = '0.0.1'
  GUID                 = '73666cf5-5c61-4592-b0db-077a4eae74b8'
  Author               = 'Ozoku'
  CompanyName          = 'Ozoku'
  Copyright            = '(c) Ozoku. MIT License'
  Description          = 'This module contains DSC resources for configuring Windows folders.'
  PowerShellVersion    = '7.2'
  DscResourcesToExport = @('FolderStructure', 'QuickAccess')
}