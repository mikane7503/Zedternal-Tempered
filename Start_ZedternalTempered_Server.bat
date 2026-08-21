@echo off
setlocal

set "SERVER_ROOT=%~dp0"
set "SERVER_EXE=%SERVER_ROOT%Binaries\Win64\KFGame.exe"
set "MAP=%~1"
if not defined MAP set "MAP=KF-BioticsLab"

if not exist "%SERVER_EXE%" (
    echo [ERROR] KFGame.exe was not found:
    echo         %SERVER_EXE%
    echo Place this BAT in the Killing Floor 2 dedicated-server root folder.
    pause
    exit /b 1
)

"%SERVER_EXE%" server "%MAP%?Game=ZedternalTempered.ZTGameInfo_Endless?mutator=ZedternalTempered.DKMutator" -log

endlocal
