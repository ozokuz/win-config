Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Invoke-WebRequest -Uri https://raw.githubusercontent.com/ozokuz/win-config/simplified/bootstrap.ps1 -OutFile "$env:USERPROFILE\Downloads\bootstrap.ps1"
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Verb RunAs -File $env:USERPROFILE\Downloads\bootstrap.ps1" -Wait