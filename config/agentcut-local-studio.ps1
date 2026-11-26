[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$Root = 'F:\AI-Video-Studio'
$NodeHome = Join-Path $Root 'software\node'
$Node = Join-Path $NodeHome 'node.exe'
$StudioRoot = Join-Path $Root 'cache\agentcut-studio-0.2.33'
$Npm = Join-Path $NodeHome 'npm.cmd'

if (-not (Test-Path -LiteralPath $StudioRoot)) {
    throw "Local Studio source is missing: $StudioRoot"
}

$env:PATH = "$NodeHome;$env:PATH"
$env:npm_config_userconfig = Join-Path $Root 'config\npmrc'
$env:npm_config_cache = Join-Path $Root 'cache\npm'
$env:TEMP = Join-Path $Root 'cache\temp'
$env:TMP = $env:TEMP
$env:NEXT_TELEMETRY_DISABLED = '1'

Set-Location -LiteralPath $StudioRoot

Write-Host 'Agentcut local Studio 0.2.33'
Write-Host 'URL: http://localhost:3000/studio'
Write-Host ''

$StandaloneRoot = Join-Path $StudioRoot '.next\standalone'
$StandaloneServer = Join-Path $StandaloneRoot 'server.js'
if (Test-Path -LiteralPath $StandaloneServer) {
    $env:HOSTNAME = '127.0.0.1'
    $env:PORT = '3000'
    Set-Location -LiteralPath $StandaloneRoot
    Write-Host 'Mode: standalone production build'
    & $Node $StandaloneServer
} else {
    Write-Host 'Mode: development (production build not available)'
    & $Npm run dev -- --hostname 127.0.0.1 --port 3000
}
exit $LASTEXITCODE
