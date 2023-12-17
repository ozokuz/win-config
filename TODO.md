$Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Set-ItemProperty -Path $Path -Name AppsUseLightTheme -Value 0
Set-ItemProperty -Path $Path -Name SystemUsesLightTheme -Value 0
$Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $Path -Name ShowTaskViewButton -Value 0
wsl.exe --install

features: Hyper-V, .NET 3.5
settings: explorer start in this pc
apps: powertoys, everything

install scoop
scoop apps: neovim, winfetch, ripgrep, fd, make, gcc,
