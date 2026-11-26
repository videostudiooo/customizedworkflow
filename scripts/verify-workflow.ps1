[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$Root = 'F:\AI-Video-Studio'
$Codex = 'F:\CodexBin\bin\codex.exe'
$SkillTarget = 'F:\CodexHome\skills\ai-video-studio'
$GlobalAgents = 'F:\CodexHome\AGENTS.md'
$ConfigPath = 'F:\CodexHome\config.toml'

$Mcp = & $Codex mcp list --json 2>$null | Out-String | ConvertFrom-Json
$AgentcutConfigured = [bool]($Mcp | Where-Object { $_.name -eq 'agentcut' -or $_.Name -eq 'agentcut' })

$PromptInput = & $Codex debug prompt-input '帮我制作一个视频' 2>$null | Out-String
$SkillDiscovered = $PromptInput.Contains('ai-video-studio')
$RouterDiscovered = $PromptInput.Contains('AI Video Studio')
$GlobalMcpVisible = $PromptInput.Contains('agentcut_capabilities')

[pscustomobject]@{
    SkillTargetExists = Test-Path -LiteralPath $SkillTarget
    SkillTargetType = if (Test-Path -LiteralPath $SkillTarget) { (Get-Item -LiteralPath $SkillTarget -Force).LinkType } else { $null }
    GlobalAgentsExists = Test-Path -LiteralPath $GlobalAgents
    GlobalRouterInstalled = if (Test-Path -LiteralPath $GlobalAgents) { (Get-Content -LiteralPath $GlobalAgents -Raw).Contains('BEGIN AI Video Studio Router') } else { $false }
    McpConfigInstalled = (Get-Content -LiteralPath $ConfigPath -Raw).Contains('[mcp_servers.agentcut]')
    StableMcpWrapperConfigured = (Get-Content -LiteralPath $ConfigPath -Raw).Contains('scripts\agentcut-mcp.cmd')
    AgentcutConfigured = $AgentcutConfigured
    SkillMetadataInPrompt = $SkillDiscovered
    RouterInPrompt = $RouterDiscovered
    McpToolsInPrompt = $GlobalMcpVisible
    HelperListening = [bool](Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort 32118 -State Listen -ErrorAction SilentlyContinue)
    StudioListening = [bool](Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue)
    ControlledBrowserListening = [bool](Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort 9223 -State Listen -ErrorAction SilentlyContinue)
} | ConvertTo-Json -Depth 3
