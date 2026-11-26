[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$Root = 'F:\AI-Video-Studio'
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
$SkillSource = Join-Path $Root 'skills\ai-video-studio'
$SkillTarget = Join-Path $CodexHome 'skills\ai-video-studio'
$RouterSource = Join-Path $Root 'workflows\global-router.md'
$GlobalAgents = Join-Path $CodexHome 'AGENTS.md'
$ConfigPath = Join-Path $CodexHome 'config.toml'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$McpStart = '# BEGIN AI Video Studio managed MCP'
$McpEnd = '# END AI Video Studio managed MCP'

foreach ($Path in @($SkillSource, $RouterSource, $ConfigPath)) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required integration file is missing: $Path"
    }
}

New-Item -ItemType Directory -Path (Split-Path -Parent $SkillTarget) -Force | Out-Null

if (Test-Path -LiteralPath $SkillTarget) {
    $Existing = Get-Item -LiteralPath $SkillTarget -Force
    if ($Existing.LinkType -ne 'Junction') {
        throw "Skill target exists and is not the managed junction: $SkillTarget"
    }
    $ExistingTarget = @($Existing.Target) | Select-Object -First 1
    if (-not $ExistingTarget -or
        (Resolve-Path -LiteralPath $ExistingTarget).Path -ne (Resolve-Path -LiteralPath $SkillSource).Path) {
        throw "Skill junction points to an unexpected target: $SkillTarget"
    }
} else {
    New-Item -ItemType Junction -Path $SkillTarget -Target $SkillSource | Out-Null
}

$RouterBlock = Get-Content -LiteralPath $RouterSource -Raw
$ExistingAgents = if (Test-Path -LiteralPath $GlobalAgents) {
    Get-Content -LiteralPath $GlobalAgents -Raw
} else {
    ''
}

if ($ExistingAgents -match '(?ms)<!-- BEGIN AI Video Studio Router -->.*?<!-- END AI Video Studio Router -->') {
    $UpdatedAgents = [regex]::Replace(
        $ExistingAgents,
        '(?ms)<!-- BEGIN AI Video Studio Router -->.*?<!-- END AI Video Studio Router -->',
        $RouterBlock.TrimEnd()
    )
} elseif ($ExistingAgents.Trim()) {
    $UpdatedAgents = $ExistingAgents.TrimEnd() + "`n`n" + $RouterBlock.Trim() + "`n"
} else {
    $UpdatedAgents = $RouterBlock.Trim() + "`n"
}

if (Test-Path -LiteralPath $GlobalAgents) {
    Copy-Item -LiteralPath $GlobalAgents -Destination "$GlobalAgents.bak-ai-video-studio-$Stamp"
}
Set-Content -LiteralPath $GlobalAgents -Value $UpdatedAgents -Encoding utf8 -NoNewline

Copy-Item -LiteralPath $ConfigPath -Destination "$ConfigPath.bak-ai-video-studio-$Stamp"
$Config = Get-Content -LiteralPath $ConfigPath -Raw
$McpBlock = @"
$McpStart
[mcp_servers.agentcut]
enabled = true
required = false
command = 'cmd.exe'
args = ['/d', '/s', '/c', 'call', 'F:\AI-Video-Studio\scripts\agentcut-mcp.cmd']
env = { AGENTCUT_WORKSPACE = 'F:\AI-Video-Studio', AGENTCUT_PORT = '32118' }
cwd = 'F:\AI-Video-Studio'
startup_timeout_sec = 60
tool_timeout_sec = 1800
supports_parallel_tool_calls = false
$McpEnd
"@

if ($Config -match "(?ms)^$([regex]::Escape($McpStart)).*?^$([regex]::Escape($McpEnd))\r?\n?") {
    $UpdatedConfig = [regex]::Replace(
        $Config,
        "(?ms)^$([regex]::Escape($McpStart)).*?^$([regex]::Escape($McpEnd))\r?\n?",
        $McpBlock.TrimEnd() + "`n"
    )
} else {
    $UpdatedConfig = $Config.TrimEnd() + "`n`n" + $McpBlock.Trim() + "`n"
}
Set-Content -LiteralPath $ConfigPath -Value $UpdatedConfig -Encoding utf8 -NoNewline

[pscustomobject]@{
    SkillSource = $SkillSource
    SkillTarget = $SkillTarget
    GlobalAgents = $GlobalAgents
    Config = $ConfigPath
    ConfigBackup = "$ConfigPath.bak-ai-video-studio-$Stamp"
    McpServer = 'agentcut'
} | ConvertTo-Json -Depth 3
