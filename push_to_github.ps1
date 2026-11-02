# =====================================================================
#  LY内部 iOS · 一键推送 + 云端编译 + 自动下载 ipa
#  用法（在本机 PowerShell 里跑）：
#     .\push_to_github.ps1 -User 你的GitHub用户名 -Repo ly-ios -Token ghp_xxxxxxxx
#
#  第一次用：GitHub → Settings → Developer settings → Personal access tokens
#            → Tokens (classic) → Generate new token → 勾选 repo + workflow
#  链接：https://github.com/settings/tokens/new?scopes=repo,workflow
# =====================================================================
param(
    [Parameter(Mandatory=$true)][string]$User,
    [Parameter(Mandatory=$true)][string]$Repo,
    [Parameter(Mandatory=$true)][string]$Token,
    [string]$Message = 'build ios ly',
    [string]$Project = 'D:\ai\ios_ly',
    [string]$Out     = 'D:\ai\dist\LY内部iOS.ipa',
    [int]$WaitMin = 25
)

$ErrorActionPreference = 'Stop'
function Ok($m)   { Write-Host "[OK] $m" -ForegroundColor Green }
function Info($m) { Write-Host "[*] $m"  -ForegroundColor Cyan }
function Warn($m) { Write-Host "[!] $m"  -ForegroundColor Yellow }
function Bad($m)  { Write-Host "[X] $m"  -ForegroundColor Red; exit 1 }

# ---------- 0) 检查 git
$git = (Get-Command git -ErrorAction SilentlyContinue)
if (-not $git) { Bad '没找到 git，先装：https://registry.npmmirror.com/-/binary/git-for-windows/v2.47.1.windows.1/Git-2.47.1-64-bit.exe' }
Ok ("git: " + $git.Source)

if (-not (Test-Path (Join-Path $Project '.github\workflows\build.yml'))) {
    Bad ("工程里缺少 .github/workflows/build.yml：" + $Project)
}

# ---------- 1) 本地仓库
Push-Location $Project
if (-not (Test-Path '.git')) {
    & git init | Out-Null
    & git branch -M main 2>$null | Out-Null
    Ok '已初始化本地仓库'
}
& git add -A | Out-Null
$pending = (& git status --porcelain)
if ($pending) {
    & git -c user.name="$User" -c user.email="$User@users.noreply.github.com" commit -m "$Message" | Out-Null
    Ok '已提交'
} else { Info '没有新改动，直接推送' }
& git branch -M main 2>$null | Out-Null

# ---------- 2) 远端（带 token，避免交互登录）
$remote = "https://x-access-token:$Token@github.com/$User/$Repo.git"
& git remote remove origin 2>$null | Out-Null
& git remote add origin $remote
Info "推送中 → https://github.com/$User/$Repo"
$push = & git push -u origin main --force 2>&1
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Bad ("推送失败（仓库没建？或 token 没 repo 权限）：`n" + ($push | Select-Object -Last 4))
}
Ok '推送成功'
Pop-Location

# ---------- 3) 等 Actions 构建
$api = "https://api.github.com/repos/$User/$Repo/actions/runs?per_page=1"
$hdr = @{ Authorization = "Bearer $Token"; Accept = 'application/vnd.github+json'; 'User-Agent' = 'ly-push' }
$deadline = (Get-Date).AddMinutes($WaitMin)
$run = $null
Info '等待 Actions 启动…'
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 10
    try {
        $r = Invoke-RestMethod -Uri $api -Headers $hdr -TimeoutSec 20
        $run = $r.workflow_runs | Select-Object -First 1
        if ($run) {
            Write-Host ("    run #" + $run.run_number + " status=" + $run.status + " conclusion=" + $run.conclusion)
            if ($run.status -eq 'completed') { break }
        }
    } catch { Warn ("查询失败: " + $_.Exception.Message) }
}

if (-not $run) { Bad '没查到 workflow（检查 token 是否有 workflow 权限）' }
if ($run.conclusion -ne 'success') {
    Bad ("构建未成功：conclusion=" + $run.conclusion + "`n 查看日志：" + $run.html_url)
}
Ok ("构建成功：" + $run.html_url)

# ---------- 4) 下载 artifact
$arts = Invoke-RestMethod -Uri "https://api.github.com/repos/$User/$Repo/actions/runs/$($run.id)/artifacts" -Headers $hdr -TimeoutSec 20
$art = $arts.artifacts | Where-Object { $_.name -like '*ipa*' } | Select-Object -First 1
if (-not $art) { Bad '没找到 ipa 产物' }

Info ("下载产物: " + $art.name + " (" + [math]::Round($art.size_in_bytes/1MB,2) + " MB)")
$zip = Join-Path $env:TEMP ('lyart-' + [guid]::NewGuid().ToString('N').Substring(0,6) + '.zip')
Invoke-WebRequest -Uri $art.archive_download_url -Headers $hdr -OutFile $zip -TimeoutSec 300

$dir = Join-Path $env:TEMP ('lyart-' + [guid]::NewGuid().ToString('N').Substring(0,6))
Expand-Archive -Path $zip -DestinationPath $dir -Force
$ipa = Get-ChildItem $dir -Recurse -Filter '*.ipa' | Select-Object -First 1
if (-not $ipa) { Bad '产物里没有 .ipa' }

New-Item -ItemType Directory -Force -Path (Split-Path $Out) | Out-Null
Copy-Item $ipa.FullName $Out -Force
Remove-Item $dir, $zip -Recurse -Force -ErrorAction SilentlyContinue

$h = (Get-FileHash $Out -Algorithm SHA256).Hash
Write-Host ''
Ok ("已下载: $Out   (" + [math]::Round((Get-Item $Out).Length/1MB,2) + " MB)")
Write-Host ("   SHA256: " + $h)
Write-Host '   安装：传到 iPhone → TrollStore 打开 → Install'
