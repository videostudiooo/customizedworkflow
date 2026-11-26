[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'

$Root = 'F:\AI-Video-Studio'
$FreedFiles = 0L
$FreedItems = 0
$Removed = [System.Collections.Generic.List[object]]::new()

function Get-PathStats([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ Bytes = 0L; Files = 0 }
    }
    $Item = Get-Item -LiteralPath $Path -Force
    if (-not $Item.PSIsContainer) {
        return [pscustomobject]@{ Bytes = [long]$Item.Length; Files = 1 }
    }
    $Files = Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue
    $Bytes = ($Files | Measure-Object Length -Sum).Sum
    if ($null -eq $Bytes) { $Bytes = 0L }
    return [pscustomobject]@{ Bytes = [long]$Bytes; Files = $Files.Count }
}

function Remove-ManagedItem([string] $Path, [string] $Reason) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $Full = [IO.Path]::GetFullPath($Path)
    if (-not $Full.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe cleanup target: $Full"
    }
    $Stats = Get-PathStats $Full
    if ($PSCmdlet.ShouldProcess($Full, $Reason)) {
        Remove-Item -LiteralPath $Full -Recurse -Force
        $script:FreedFiles += $Stats.Files
        $script:FreedItems += 1
        $Removed.Add([pscustomobject]@{
            path = $Full
            reason = $Reason
            files = $Stats.Files
            bytes = $Stats.Bytes
        })
    }
}

$Before = Get-Volume -DriveLetter F

$ManagedDirectories = @(
    @{ Path = "$Root\cache\npm\_npx"; Reason = 'old npx helper cache replaced by the stable helper installation' },
    @{ Path = "$Root\cache\temp\chrome-cdp-profile"; Reason = 'old acceptance browser profile' },
    @{ Path = "$Root\cache\temp\chrome-acceptance-profile"; Reason = 'old acceptance browser profile' },
    @{ Path = "$Root\cache\temp\chrome-acceptance-profile-2"; Reason = 'old acceptance browser profile' },
    @{ Path = "$Root\cache\agentcut-studio-0.2.33\.next\cache"; Reason = 'regenerable Next.js build cache' },
    @{ Path = "$Root\node_modules\.cache"; Reason = 'regenerable Remotion webpack cache' },
    @{ Path = "$Root\projects\workflow-cross-thread-test\.studio\scratch\decode-check"; Reason = 'temporary full-decoded PNG frames used only for acceptance QA' }
)

foreach ($Entry in $ManagedDirectories) {
    Remove-ManagedItem $Entry.Path $Entry.Reason
}

$ManagedFiles = @(
    @{ Path = "$Root\cache\temp\node-v24.22.3-win-x64.zip"; Reason = 'verified portable Node installer archive already extracted' },
    @{ Path = "$Root\cache\agentcut-studio-v0.2.33.tar.gz"; Reason = 'official source archive already extracted and built' },
    @{ Path = "$Root\logs\agentcut\controlled-studio.png"; Reason = 'duplicate acceptance screenshot' },
    @{ Path = "$Root\logs\agentcut\studio-headless-dom.html"; Reason = 'empty failed browser debug output' },
    @{ Path = "$Root\logs\agentcut\studio-headless.err.log"; Reason = 'empty failed browser debug output' },
    @{ Path = "$Root\logs\agentcut\studio-initial.png"; Reason = 'superseded browser test screenshot' },
    @{ Path = "$Root\logs\agentcut\studio-local.png"; Reason = 'superseded browser test screenshot' },
    @{ Path = "$Root\logs\agentcut\studio-welcome.png"; Reason = 'superseded browser test screenshot' },
    @{ Path = "$Root\logs\agentcut\studio-welcome-loaded.png"; Reason = 'superseded browser test screenshot' },
    @{ Path = "$Root\projects\workflow-cross-thread-test\.studio\scratch\local-render.mjs"; Reason = 'temporary render harness used only for acceptance QA' }
)

foreach ($Entry in $ManagedFiles) {
    Remove-ManagedItem $Entry.Path $Entry.Reason
}

$ReportMain = "$Root\reports\AGENTCUT-POST-DEPLOYMENT-ACCEPTANCE.md"
$ReportDuplicate = "$Root\reports\AGENTCUT-POST-DEPLOYMENT-ACCEPTANCE.zh.md"
if ((Test-Path -LiteralPath $ReportMain) -and (Test-Path -LiteralPath $ReportDuplicate)) {
    $HashMain = (Get-FileHash -LiteralPath $ReportMain -Algorithm SHA256).Hash
    $HashDuplicate = (Get-FileHash -LiteralPath $ReportDuplicate -Algorithm SHA256).Hash
    if ($HashMain -ne $HashDuplicate) {
        throw 'The two acceptance reports differ; duplicate report was not removed.'
    }
    Remove-ManagedItem $ReportDuplicate 'byte-identical duplicate acceptance report'
}

$NodeHome = Join-Path $Root 'software\node'
$env:PATH = "$NodeHome;$env:PATH"
$env:npm_config_userconfig = Join-Path $Root 'config\npmrc'
$env:npm_config_cache = Join-Path $Root 'cache\npm'
if ($PSCmdlet.ShouldProcess("$Root\cache\npm", 'regenerable npm cache')) {
    & (Join-Path $NodeHome 'npm.cmd') cache clean --force
    if ($LASTEXITCODE -ne 0) { throw 'npm cache clean failed.' }
}

$After = Get-Volume -DriveLetter F
[pscustomobject]@{
    beforeFreeGB = [math]::Round($Before.SizeRemaining / 1GB, 2)
    afterFreeGB = [math]::Round($After.SizeRemaining / 1GB, 2)
    freedGB = [math]::Round(($After.SizeRemaining - $Before.SizeRemaining) / 1GB, 2)
    removedFileCount = $FreedFiles
    removedItemCount = $FreedItems
    removedItems = $Removed
} | ConvertTo-Json -Depth 5
