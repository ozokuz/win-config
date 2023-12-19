Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop update
scoop bucket add extras
scoop bucket add games
scoop install bat fd fzf gcc grep lazygit make neovim nodejs-lts pnpm python ripgrep starship wget