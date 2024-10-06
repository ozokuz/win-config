# Enable Prediction
Set-PSReadLineOption -PredictionSource History

# Fzf
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# Aliases
Set-Alias v nvim
Set-Alias pw packwiz
function .. {
  cd ..
}
function l {
  eza --icons --git -la
}
function ln ($value, $path) {
  New-Item -Type SymbolicLink -Value $value -Path $path
}
function which ($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

# Git
Set-Alias g git
Set-Alias lg lazygit
Import-Module posh-git

# Prompt
Invoke-Expression (&starship init powershell)

# Z
Invoke-Expression (& { (zoxide init powershell | Out-String) })
