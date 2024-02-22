[DscResource()]
class FolderStructure {
  [DscProperty()] [string[]] $Folders

  [DscProperty(Key)] [string] $SID

  [DscProperty(NotConfigurable)] [string[]] $ExistingFolders

  [FolderStructure] Get() {
    $currentState = [FolderStructure]::new()

    $currentState.ExistingFolders = $this.Folders | ForEach-Object {
      if (Test-Path -Path $_) {
        $_
      }
    }

    $currentState.Folders = $this.Folders

    return $currentState
  }

  [bool] Test() {
    $currentState = $this.Get()

    return $this.Folders -eq $currentState.ExistingFolders
  }

  [void] Set() {
    $this.Folders | ForEach-Object {
      if (-not(Test-Path -Path $_)) {
        New-Item -Path $_ -ItemType Directory
      }
    }
  }
}

$global:QuickAccessLocation = "shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}"

[DscResource()]
class QuickAccess {
  [DscProperty()] [bool] $UserFolder = $false
  [DscProperty()] [bool] $Desktop = $true
  [DscProperty()] [bool] $Downloads = $true
  [DscProperty()] [bool] $Documents = $true
  [DscProperty()] [bool] $Pictures = $true
  [DscProperty()] [bool] $Videos = $true
  [DscProperty()] [bool] $Music = $true
  [DscProperty()] [bool] $RecycleBin = $false
  [DscProperty()] [string[]] $OtherPins = @()

  [DscProperty(Key)] [string] $SID

  [DscProperty(NotConfigurable)] [string[]] $Pins
  [DscProperty(NotConfigurable)] [string[]] $ExistingPins

  [QuickAccess] Get() {
    $currentState = [QuickAccess]::new()

    $o = New-Object -ComObject shell.application
    $quickAccess = $o.Namespace($global:QuickAccessLocation)

    $currentState.Pins = @()

    if ($this.UserFolder) {
      $currentState.Pins += "$env:USERPROFILE"
    }

    if ($this.Desktop) {
      $currentState.Pins += "Desktop"
    }

    if ($this.Downloads) {
      $currentState.Pins += "Downloads"
    }

    if ($this.Documents) {
      $currentState.Pins += "Documents"
    }

    if ($this.Pictures) {
      $currentState.Pins += "Pictures"
    }

    if ($this.Videos) {
      $currentState.Pins += "Videos"
    }

    if ($this.Music) {
      $currentState.Pins += "Music"
    }

    if ($this.RecycleBin) {
      $currentState.Pins += "Recycle Bin"
    }

    $currentState.Pins += $this.OtherPins

    $currentState.OtherPins = $this.OtherPins

    $currentState.ExistingPins = @($quickAccess.Items() | ForEach-Object { $_.Name })

    return $currentState
  }

  [bool] Test() {
    $currentState = $this.Get()

    return $currentState.Pins -eq $currentState.ExistingPins
  }

  [void] Set() {
    $currentState = $this.Get()

    $o = New-Object -ComObject shell.application

    $userProfile = "$env:USERPROFILE"

    if ($this.UserFolder -and -not($currentState.ExistingPins | Where-Object { $_ -eq "$env:USERPROFILE" })) {
      $o.Namespace($userProfile).Self.InvokeVerb("pintohome")
    }

    if ($this.Desktop -and -not($currentState.ExistingPins | Where-Object { $_ -eq "Desktop" })) {
      $o.Namespace("$userProfile\\Desktop").Self.InvokeVerb("pintohome")
    }

    if ($this.Downloads -and -not($currentState.ExistingPins | Where-Object { $_ -eq "Downloads" })) {
      $o.Namespace("$userProfile\\Downloads").Self.InvokeVerb("pintohome")
    }

    if ($this.Documents -and -not($currentState.ExistingPins | Where-Object { $_ -eq "Documents" })) {
      $o.Namespace("$userProfile\\Documents").Self.InvokeVerb("pintohome")
    }

    if ($this.Pictures -and -not($currentState.ExistingPins | Where-Object { $_ -eq "Pictures" })) {
      $o.Namespace("$userProfile\\Pictures").Self.InvokeVerb("pintohome")
    }

    if ($this.Videos -and -not($currentState.ExistingPins | Where-Object { $_ -eq "Videos" })) {
      $o.Namespace("$userProfile\\Videos").Self.InvokeVerb("pintohome")
    }

    if ($this.Music -and -not($currentState.ExistingPins | Where-Object { $_ -eq "Music" })) {
      $o.Namespace("$userProfile\\Music").Self.InvokeVerb("pintohome")
    }

    if ($this.RecycleBin -and -not($currentState.ExistingPins | Where-Object { $_ -eq "Recycle Bin" })) {
      $o.Namespace("::{645FF040-5081-101B-9F08-00AA002F954E}").Self.InvokeVerb("pintohome")
    }

    $this.OtherPins | ForEach-Object {
      $toPin = $_
      if (-not($currentState.ExistingPins | Where-Object { $toPin -eq $_ })) {
        $o.Namespace($toPin).Self.InvokeVerb("pintohome")
      }
    }
  }
}