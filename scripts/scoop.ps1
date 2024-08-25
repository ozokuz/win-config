Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop bucket add extras
scoop install bat eza fd fzf gcc grep lazygit make neovim pnpm python ripgrep starship wget zoxide
New-Item -Type File -Path "$env:USERPROFILE\scoop\.complete"