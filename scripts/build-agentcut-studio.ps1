[CmdletBinding()]
param(
    [switch] $SkipBuild
)

$ErrorActionPreference = 'Stop'

$Root = 'F:\AI-Video-Studio'
$NodeHome = Join-Path $Root 'software\node'
$Npm = Join-Path $NodeHome 'npm.cmd'
$StudioRoot = Join-Path $Root 'cache\agentcut-studio-0.2.33'
$Standalone = Join-Path $StudioRoot '.next\standalone'

foreach ($Path in @($Npm, $StudioRoot)) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required Studio build path is missing: $Path"
    }
}

$env:PATH = "$NodeHome;$env:PATH"
$env:npm_config_userconfig = Join-Path $Root 'config\npmrc'
$env:npm_config_cache = Join-Path $Root 'cache\npm'
$env:TEMP = Join-Path $Root 'cache\temp'
$env:TMP = $env:TEMP
$env:NEXT_TELEMETRY_DISABLED = '1'

Set-Location -LiteralPath $StudioRoot

if (-not $SkipBuild) {
    & $Npm run build
    if ($LASTEXITCODE -ne 0) {
        throw 'Agentcut Studio production build failed.'
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $Standalone 'server.js'))) {
    throw 'The production build did not create .next\standalone\server.js.'
}

New-Item -ItemType Directory -Path (Join-Path $Standalone '.next') -Force | Out-Null

$StaticSource = Join-Path $StudioRoot '.next\static'
$StaticTarget = Join-Path $Standalone '.next\static'
if (Test-Path -LiteralPath $StaticSource) {
    & robocopy.exe $StaticSource $StaticTarget /E /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -gt 7) { throw 'Failed to stage Next.js static assets.' }
}

$PublicSource = Join-Path $StudioRoot 'public'
$PublicTarget = Join-Path $Standalone 'public'
if (Test-Path -LiteralPath $PublicSource) {
    & robocopy.exe $PublicSource $PublicTarget /E /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -gt 7) { throw 'Failed to stage public assets.' }
}

[pscustomobject]@{
    StudioRoot = $StudioRoot
    StandaloneServer = Join-Path $Standalone 'server.js'
    StaticStaged = Test-Path -LiteralPath $StaticTarget
    PublicStaged = Test-Path -LiteralPath $PublicTarget
} | ConvertTo-Json -Depth 3
