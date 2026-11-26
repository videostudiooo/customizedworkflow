[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $AgentcutArgs
)

$ErrorActionPreference = 'Stop'

$Root = 'F:\AI-Video-Studio'
$NodeHome = Join-Path $Root 'software\node'
$Node = Join-Path $NodeHome 'node.exe'
$HelperCli = Join-Path $Root 'software\agentcut-helper\node_modules\agentcut\dist\studio\cli.js'

$RequiredPaths = @(
    $Node,
    $HelperCli,
    (Join-Path $Root 'cache\npm'),
    (Join-Path $Root 'cache\models'),
    (Join-Path $Root 'cache\temp'),
    (Join-Path $Root 'tools\agentcut'),
    (Join-Path $Root 'renders_temp\agentcut-frames'),
    (Join-Path $Root 'logs\agentcut'),
    (Join-Path $Root 'config\npmrc')
)

foreach ($Path in $RequiredPaths) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required deployment path is missing: $Path"
    }
}

$env:PATH = "$NodeHome;$env:PATH"
$env:npm_config_userconfig = Join-Path $Root 'config\npmrc'
$env:npm_config_cache = Join-Path $Root 'cache\npm'
$env:AGENTCUT_DIR = $Root
$env:AGENTCUT_TOOLS = Join-Path $Root 'tools\agentcut'
$env:AGENTCUT_MODEL_CACHE = Join-Path $Root 'cache\models'
$env:AGENTCUT_FRAMES_DIR = Join-Path $Root 'renders_temp\agentcut-frames'
$env:AGENTCUT_LOG = Join-Path $Root 'logs\agentcut\agentcut-mcp.log'
$env:TEMP = Join-Path $Root 'cache\temp'
$env:TMP = $env:TEMP

Write-Host "AI Video Studio / Agentcut 0.2.33"
Write-Host "Workspace: $Root"
Write-Host "Node:      $NodeHome"
Write-Host "npm cache: $env:npm_config_cache"
Write-Host "Tools:     $env:AGENTCUT_TOOLS"
Write-Host "Models:    $env:AGENTCUT_MODEL_CACHE"
Write-Host "Log:       $env:AGENTCUT_LOG"
Write-Host "TEMP:      $env:TEMP"
Write-Host ''

$Arguments = @($HelperCli, '--dir', $Root, '--agent', 'codex', '--origin', 'http://localhost:3000') + $AgentcutArgs

& $Node @Arguments
exit $LASTEXITCODE
