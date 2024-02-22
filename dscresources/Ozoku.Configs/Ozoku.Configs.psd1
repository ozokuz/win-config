@{
  RootModule           = 'Ozoku.Configs.psm1'
  ModuleVersion        = '0.0.1'
  GUID                 = '092f0957-2471-4298-b2e7-3c9549a49de4'
  Author               = 'Ozoku'
  CompanyName          = 'Ozoku'
  Copyright            = '(c) Ozoku. MIT License'
  Description          = 'This module contains a DSC resource for creating symlinked configuration files.'
  PowerShellVersion    = '7.2'
  DscResourcesToExport = @('CreateSymlink')
}