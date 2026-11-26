[CmdletBinding()]
param(
    [switch] $VisibleBrowser
)

$ErrorActionPreference = 'Stop'

$Root = 'F:\AI-Video-Studio'
$Node = Join-Path $Root 'software\node\node.exe'
$Npm = Join-Path $Root 'software\node\npm.cmd'
$HelperCli = Join-Path $Root 'software\agentcut-helper\node_modules\agentcut\dist\studio\cli.js'
$StudioScript = Join-Path $Root 'config\agentcut-local-studio.ps1'
$LogRoot = Join-Path $Root 'logs\agentcut'
$StatePath = Join-Path $LogRoot 'service-state.json'
$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$BrowserProfile = Join-Path $Root 'cache\browser\agentcut-ui'
$BrowserPort = 9223

foreach ($Path in @($Node, $Npm, $HelperCli, $StudioScript, $LogRoot)) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required service path is missing: $Path"
    }
}

New-Item -ItemType Directory -Path $BrowserProfile -Force | Out-Null

function Test-LocalPort([int] $Port) {
    return [bool](Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

function Wait-LocalPort([int] $Port, [int] $Seconds = 30) {
    $Deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $Deadline) {
        if (Test-LocalPort $Port) { return $true }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

$State = [ordered]@{
    updatedAt = (Get-Date).ToString('o')
    helperPid = $null
    studioPid = $null
    browserPid = $null
    helperPort = 32118
    studioPort = 3000
    browserPort = $BrowserPort
}

if (Test-Path -LiteralPath $StatePath) {
    try {
        $Previous = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
        foreach ($Name in @('helperPid', 'studioPid', 'browserPid')) {
            if ($Previous.$Name) { $State[$Name] = $Previous.$Name }
        }
    } catch {}
}

if (-not (Test-LocalPort 32118)) {
    $Out = Join-Path $LogRoot 'service-helper.out.log'
    $Err = Join-Path $LogRoot 'service-helper.err.log'
    $Process = Start-Process -FilePath $Node `
        -ArgumentList @($HelperCli, '--dir', $Root, '--agent', 'codex', '--origin', 'http://localhost:3000') `
        -WorkingDirectory $Root -WindowStyle Hidden `
        -RedirectStandardOutput $Out -RedirectStandardError $Err -PassThru
    $State.helperPid = $Process.Id
}

if (-not (Wait-LocalPort 32118 30)) {
    throw 'Agentcut Helper did not start on 127.0.0.1:32118.'
}

if (-not (Test-LocalPort 3000)) {
    $Out = Join-Path $LogRoot 'service-studio.out.log'
    $Err = Join-Path $LogRoot 'service-studio.err.log'
    $Process = Start-Process -FilePath 'powershell.exe' `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $StudioScript) `
        -WorkingDirectory $Root -WindowStyle Hidden `
        -RedirectStandardOutput $Out -RedirectStandardError $Err -PassThru
    $State.studioPid = $Process.Id
}

if (-not (Wait-LocalPort 3000 60)) {
    throw 'Agentcut Studio did not start on 127.0.0.1:3000.'
}

if (-not (Test-LocalPort $BrowserPort)) {
    if (-not (Test-Path -LiteralPath $Chrome)) {
        throw "Chrome is not installed at $Chrome"
    }
    $BrowserArgs = @(
        $(if ($VisibleBrowser) { '--new-window' } else { '--headless=new' }),
        '--no-first-run',
        '--no-default-browser-check',
        "--user-data-dir=$BrowserProfile",
        "--remote-debugging-address=127.0.0.1",
        "--remote-debugging-port=$BrowserPort",
        'http://localhost:3000/studio'
    )
    $Process = Start-Process -FilePath $Chrome -ArgumentList $BrowserArgs `
        -WindowStyle Hidden -PassThru
    $State.browserPid = $Process.Id
}

if (-not (Wait-LocalPort $BrowserPort 30)) {
    throw "The controlled Studio browser did not expose port $BrowserPort."
}

$Deadline = (Get-Date).AddSeconds(30)
$StudioPage = $null
while ((Get-Date) -lt $Deadline) {
    try {
        $Pages = Invoke-RestMethod -Uri "http://127.0.0.1:$BrowserPort/json" -TimeoutSec 3
        $StudioPage = $Pages | Where-Object { $_.type -eq 'page' -and $_.url -like 'http://localhost:3000/*' } | Select-Object -First 1
        if ($StudioPage) { break }
    } catch {}
    Start-Sleep -Milliseconds 500
}

if (-not $StudioPage) {
    throw 'Studio is running, but the controlled browser has not opened it.'
}

$State.updatedAt = (Get-Date).ToString('o')
$State | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $StatePath -Encoding utf8
$State | ConvertTo-Json -Depth 3
