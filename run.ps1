Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Invoke-WebRequest -Uri https://raw.githubusercontent.com/ozokuz/win-config/simplified/configuration.ps1 -OutFile "$env:USERPROFILE\Downloads\bootstrap.ps1"
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $env:USERPROFILE\Downloads\bootstrap.ps1" -Wait -Verb RunAs