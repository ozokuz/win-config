$exists = Test-Path $env:USERPROFILE\Tools\OOSU10.exe -PathType Leaf
if ($exists)
{
    exit 0
}

mkdir $env:USERPROFILE\Tools
cd $env:USERPROFILE\Tools
Invoke-WebRequest https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe -OutFile .\OOSU10.exe
Invoke-WebRequest https://raw.githubusercontent.com/ozokuz/win-config/main/ooshutup10.cfg -UseBasicParsing -OutFile .\oosu.txt
.\OOSU10.exe .\ooshutup10.cfg /quiet