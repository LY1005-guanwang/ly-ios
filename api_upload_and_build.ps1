# =====================================================================
#  LY内部 iOS · 全 API 上传 + 云端编译 + 取回 ipa
#  （不依赖 github.com 网页 / git 推送，全部走 api.github.com）
#  用法： .\api_upload_and_build.ps1 -Token ghp_xxxx [-Repo ly-ios] [-WaitMin 30]
# =====================================================================
param(
    [Parameter(Mandatory=$true)][string]$Token,
    [string]$Repo = 'ly-ios',
    [string]$Project = 'D:\ai\ios_ly',
    [string]$Out = 'D:\ai\dist\LY内部iOS.ipa',
    [int]$WaitMin = 30
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$API = 'https://api.github.com'
$H = @{
    Authorization = "Bearer $Token"
    Accept        = 'application/vnd.github+json'
    'User-Agent'  = 'ly-builder'
    'X-GitHub-Api-Version' = '2022-11-28'
}
function Ok($m)   { Write-Host "[OK] $m" -ForegroundColor Green }
function Info($m) { Write-Host "[*] $m"  -ForegroundColor Cyan }
function Warn($m) { Write-Host "[!] $m"  -ForegroundColor Yellow }
function Bad($m)  { Write-Host "[X] $m"  -ForegroundColor Red; exit 1 }

function Api($method, $path, $bodyObj) {
    $json = $null
    if ($null -ne $bodyObj) { $json = [Text.Encoding]::UTF8.GetBytes(($bodyObj | ConvertTo-Json -Depth 6 -Compress)) }
    try {
        if ($json) { return Invoke-RestMethod -Method $method -Uri ($API + $path) -Headers $H -Body $json -ContentType 'application/json' -TimeoutSec 60 }
        return Invoke-RestMethod -Method $method -Uri ($API + $path) -Headers $H -TimeoutSec 60
    } catch {
        $code = $null; try { $code = $_.Exception.Response.StatusCode.value__ } catch {}
        throw "API $method $path 失败 (HTTP $code): $($_.Exception.Message)"
    }
}

# ---------- 1) 我是谁
$me = Api 'GET' '/user' $null
$owner = $me.login
Ok ("已认证: " + $owner)

# ---------- 2) 建仓库
try {
    $r = Api 'GET' "/repos/$owner/$Repo" $null
    Info ("仓库已存在: " + $r.html_url)
} catch {
    Info '创建仓库…'
    $null = Api 'POST' '/user/repos' @{
        name = $Repo
        private = $false
        auto_init = $false
        description = 'LY内部 iOS'
    }
    Ok ("仓库已创建: https://github.com/$owner/$Repo")
}

# ---------- 3) 上传文件（逐个 contents API）
$files = Get-ChildItem $Project -Recurse -File |
         Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.Name -notin @('.devcode') }
Info ("上传 " + $files.Count + " 个文件…")
$n = 0
foreach ($f in $files) {
    $rel = $f.FullName.Substring($Project.Length + 1).Replace('\', '/')
    $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($f.FullName))
    $sha = $null
    try { $sha = (Api 'GET' "/repos/$owner/$Repo/contents/$rel" $null).sha } catch { }
    $body = @{ message = "upload $rel"; content = $b64 }
    if ($sha) { $body.sha = $sha }
    try {
        $null = Api 'PUT' "/repos/$owner/$Repo/contents/$rel" $body
        $n++
    } catch {
        Warn ("跳过 " + $rel + " : " + $_.Exception.Message)
    }
}
Ok ("已上传 " + $n + " 个文件")

# ---------- 4) 触发构建
Info '触发 workflow…'
Api 'POST' "/repos/$owner/$Repo/actions/workflows/build.yml/dispatches" @{ ref = 'main' } | Out-Null
Ok '已触发 build.yml'

# ---------- 5) 等结果
$deadline = (Get-Date).AddMinutes($WaitMin)
$run = $null
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 12
    try {
        $runs = Api 'GET' "/repos/$owner/$Repo/actions/runs?per_page=1" $null
        $run = $runs.workflow_runs | Select-Object -First 1
        if ($run) {
            Write-Host ("    run #" + $run.run_number + " " + $run.status + " / " + $run.conclusion)
            if ($run.status -eq 'completed') { break }
        }
    } catch { Warn ("轮询失败: " + $_.Exception.Message) }
}
if (-not $run) { Bad '没拿到 run（检查 token 的 workflow 权限）' }
if ($run.conclusion -ne 'success') { Bad ("构建失败: " + $run.conclusion + "  日志: " + $run.html_url) }
Ok ("构建成功: " + $run.html_url)

# ---------- 6) 从仓库取回 base64 分片（绕开被墙的 artifact 域名）
Info '读取 dist/ 分片…'
$parts = @()
try { $parts = Api 'GET' "/repos/$owner/$Repo/contents/dist" $null } catch { }
if (-not $parts -or $parts.Count -eq 0) { Bad 'dist/ 里没有分片（workflow 的回传步骤可能失败）' }

$sb = New-Object System.Text.StringBuilder
foreach ($p in ($parts | Sort-Object name)) {
    $c = Api 'GET' "/repos/$owner/$Repo/contents/$($p.path)" $null
    $txt = ($c.content -replace "\s", '')
    [void]$sb.Append($txt)
    Write-Host ("    " + $p.name + " " + $p.size + " B")
}
$bytes = [Convert]::FromBase64String($sb.ToString())
New-Item -ItemType Directory -Force -Path (Split-Path $Out) | Out-Null
[IO.File]::WriteAllBytes($Out, $bytes)

$h = (Get-FileHash $Out -Algorithm SHA256).Hash
Write-Host ''
Ok ("ipa 已就绪: " + $Out + "  (" + [math]::Round($bytes.Length/1MB,2) + " MB)")
Write-Host ("   SHA256: " + $h)
Write-Host '   安装：传到 iPhone → TrollStore → Install'
