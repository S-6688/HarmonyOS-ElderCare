@echo off
setlocal

set "PROJECT_DIR=%~dp0"
set "DEVECO_HVIGOR=D:\DevEco Studio\tools\hvigor\bin\hvigorw.bat"
set "NODE_HOME=D:\DevEco Studio\tools\node"

if not exist "%DEVECO_HVIGOR%" (
  echo ERROR: DevEco Hvigor was not found at "%DEVECO_HVIGOR%".
  echo Please update DEVECO_HVIGOR in %~nx0 to match your DevEco Studio installation.
  exit /b 1
)

if not exist "%NODE_HOME%\node.exe" (
  echo ERROR: DevEco Node.js was not found at "%NODE_HOME%\node.exe".
  echo Please update NODE_HOME in %~nx0 to match your DevEco Studio installation.
  exit /b 1
)

set "PATH=%NODE_HOME%;%PATH%"
call "%DEVECO_HVIGOR%" %*
exit /b %ERRORLEVEL%
