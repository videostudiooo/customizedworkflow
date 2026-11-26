@echo off
setlocal

set "ROOT=F:\AI-Video-Studio"
set "NODE=%ROOT%\software\node\node.exe"
set "HELPER=%ROOT%\software\agentcut-helper\node_modules\agentcut\dist\index.js"
set "ENSURE=%ROOT%\scripts\ensure-agentcut-services.ps1"
set "LOG=%ROOT%\logs\agentcut\mcp-wrapper.log"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ENSURE%" >>"%LOG%" 2>&1
if errorlevel 1 exit /b %errorlevel%

set "AGENTCUT_WORKSPACE=%ROOT%"
set "AGENTCUT_PORT=32118"
"%NODE%" "%HELPER%"
exit /b %errorlevel%
