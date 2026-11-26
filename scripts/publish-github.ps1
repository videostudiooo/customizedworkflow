[CmdletBinding()]
param(
    [string] $Owner = 'videostudiooo',
    [string] $Repository = 'customizedworkflow',
    [string] $Branch = 'main',
    [string] $Message = 'feat: implement AI Video Studio workflow'
)

$ErrorActionPreference = 'Stop'

$Root = 'F:\AI-Video-Studio'
$Git = (Get-Command git -ErrorAction Stop).Source
$GcmCandidates = @(
    'C:\Program Files\WindowsApps\OpenAI.CodexPrimaryRuntime.v26-1123-915-0_26.1123.915.0_x64__3k8sg7r9htsxt\dependencies\native\git\ucrt64\bin\git-credential-manager.exe'
)
$GitRoot = Split-Path (Split-Path $Git -Parent) -Parent
$GcmCandidates += Get-ChildItem -LiteralPath $GitRoot -Recurse -Filter 'git-credential-manager.exe' -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName
$Gcm = $GcmCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $Gcm) { throw 'Git Credential Manager was not found.' }

function Get-GitHubCredential {
    $StartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $StartInfo.FileName = $Gcm
    $StartInfo.Arguments = 'get --no-ui'
    $StartInfo.RedirectStandardInput = $true
    $StartInfo.RedirectStandardOutput = $true
    $StartInfo.RedirectStandardError = $true
    $StartInfo.UseShellExecute = $false
    $StartInfo.Environment['GIT_TERMINAL_PROMPT'] = '0'
    $Process = [System.Diagnostics.Process]::Start($StartInfo)
    $Process.StandardInput.Write("protocol=https`nhost=github.com`n`n")
    $Process.StandardInput.Close()
    $Output = $Process.StandardOutput.ReadToEnd()
    $ErrorOutput = $Process.StandardError.ReadToEnd()
    $Process.WaitForExit()
    if ($Process.ExitCode -ne 0) {
        throw "GitHub credential lookup failed: $($ErrorOutput.Trim())"
    }
    $Token = [regex]::Match($Output, '(?m)^password=(.+)$').Groups[1].Value
    if (-not $Token) { throw 'No stored GitHub credential is available.' }
    return $Token
}

$Token = Get-GitHubCredential
$Headers = @{
    Authorization = "Bearer $Token"
    'User-Agent' = 'AI-Video-Studio-publisher'
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
}

function Invoke-GitHub {
    param(
        [string] $Method,
        [string] $Path,
        [object] $Body = $null
    )
    $Parameters = @{
        Method = $Method
        Uri = "https://api.github.com$Path"
        Headers = $Headers
        ContentType = 'application/json'
        TimeoutSec = 120
    }
    if ($null -ne $Body) {
        $Parameters.Body = $Body | ConvertTo-Json -Depth 20 -Compress
    }
    return Invoke-RestMethod @Parameters
}

try {
    Set-Location -LiteralPath $Root
    & $Git add -A
    if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
    & $Git diff --cached --check
    if ($LASTEXITCODE -ne 0) { throw 'git diff --cached --check failed.' }

    $LocalTree = (& $Git write-tree).Trim()
    if (-not $LocalTree) { throw 'Could not create a local Git tree.' }

    $Ref = Invoke-GitHub -Method GET -Path "/repos/$Owner/$Repository/git/ref/heads/$Branch"
    $BaseSha = $Ref.object.sha

    $Files = @(& $Git ls-files)
    if (-not $Files.Count) { throw 'No staged repository files were found.' }

    $Entries = [System.Collections.Generic.List[object]]::new()
    foreach ($RelativePath in $Files) {
        $ReadInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $ReadInfo.FileName = $Git
        $ReadInfo.UseShellExecute = $false
        $ReadInfo.RedirectStandardOutput = $true
        $ReadInfo.RedirectStandardError = $true
        $ReadInfo.ArgumentList.Add('cat-file')
        $ReadInfo.ArgumentList.Add('blob')
        $ReadInfo.ArgumentList.Add(":$RelativePath")
        $Reader = [System.Diagnostics.Process]::Start($ReadInfo)
        $Memory = [IO.MemoryStream]::new()
        $Reader.StandardOutput.BaseStream.CopyTo($Memory)
        $ReadError = $Reader.StandardError.ReadToEnd()
        $Reader.WaitForExit()
        if ($Reader.ExitCode -ne 0) {
            throw "Could not read staged Git blob for ${RelativePath}: $ReadError"
        }
        $Bytes = $Memory.ToArray()
        $Blob = Invoke-GitHub -Method POST -Path "/repos/$Owner/$Repository/git/blobs" -Body @{
            content = [Convert]::ToBase64String($Bytes)
            encoding = 'base64'
        }
        $Entries.Add(@{
            path = $RelativePath.Replace('\', '/')
            mode = '100644'
            type = 'blob'
            sha = $Blob.sha
        })
    }

    $Tree = Invoke-GitHub -Method POST -Path "/repos/$Owner/$Repository/git/trees" -Body @{
        tree = $Entries
    }
    if ($Tree.sha -ne $LocalTree) {
        throw "Remote tree $($Tree.sha) does not match local tree $LocalTree."
    }

    $Commit = Invoke-GitHub -Method POST -Path "/repos/$Owner/$Repository/git/commits" -Body @{
        message = $Message
        tree = $Tree.sha
        parents = @($BaseSha)
    }

    $UpdatedRef = Invoke-GitHub -Method PATCH -Path "/repos/$Owner/$Repository/git/refs/heads/$Branch" -Body @{
        sha = $Commit.sha
        force = $false
    }

    [pscustomobject]@{
        owner = $Owner
        repository = $Repository
        branch = $Branch
        previousCommit = $BaseSha
        commit = $Commit.sha
        commitUrl = $Commit.html_url
        tree = $Tree.sha
        localTree = $LocalTree
        files = $Files.Count
        refSha = $UpdatedRef.object.sha
    } | ConvertTo-Json -Depth 4
}
finally {
    Remove-Variable Token -ErrorAction SilentlyContinue
}
