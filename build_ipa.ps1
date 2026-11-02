# =====================================================================
#  LY内部 iOS · 打包脚本（Windows 侧）
#  前提：WSL 里已装好 Theos + iOS SDK（见 README）
#  用法： .\build_ipa.ps1                # 编译 + 加固 + 出 ipa
#         .\build_ipa.ps1 -SkipBuild     # 只重新打包
# =====================================================================
param(
    [switch]$SkipBuild,
    [string]$Out = 'D:\ai\dist\LY内部iOS.ipa'
)
$ErrorActionPreference = 'Stop'
function Ok($m)   { Write-Host "[OK] $m" -ForegroundColor Green }
function Info($m) { Write-Host "[*] $m"  -ForegroundColor Cyan }
function Bad($m)  { Write-Host "[X] $m"  -ForegroundColor Red; exit 1 }

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $SkipBuild) {
    Info '在 WSL(Theos) 里编译…'
    $cmd = 'cd /mnt/' + ($Root.Substring(0,1).ToLower()) + $Root.Substring(2).Replace('\','/') + ' && make clean package 2>&1 | tail -40'
    wsl -e bash -lc $cmd
    if ($LASTEXITCODE -ne 0) { Bad '编译失败：先确认 WSL 里 theos 环境变量已 source' }
}

# 收集产物
$app = Get-ChildItem "$Root\.theos\obj" -Recurse -Directory -Filter 'LyInternal.app' -ErrorAction SilentlyContinue |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $app) { Bad '找不到 LyInternal.app（编译没成功？）' }
$appex = Get-ChildItem "$Root\.theos\obj" -Recurse -Directory -Filter 'LyTunnel.appex' -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $appex) { Bad '找不到 LyTunnel.appex（隧道扩展没编译出来？）' }

$stage = Join-Path $env:TEMP ('lyipa-' + [guid]::NewGuid().ToString('N').Substring(0,8))
$payload = Join-Path $stage 'Payload'
$dest    = Join-Path $payload 'LyInternal.app'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item "$($app.FullName)\*" $dest -Recurse -Force
$plugins = Join-Path $dest 'PlugIns'
New-Item -ItemType Directory -Force -Path $plugins | Out-Null
Copy-Item $appex.FullName $plugins -Recurse -Force
# 资源补齐
Copy-Item "$Root\Resources\ly_pub.pem" $dest -Force -ErrorAction SilentlyContinue
Ok ("产物收集完成: " + $dest)

# 加固（在 WSL 里跑 harden.sh）
Info '加固 / fakesign…'
$wslRoot = '/mnt/' + $Root.Substring(0,1).ToLower() + $Root.Substring(2).Replace('\','/')
$wslApp  = '/mnt/' + $dest.Substring(0,1).ToLower() + $dest.Substring(2).Replace('\','/')
$wslEnt  = $wslRoot + '/ly_internal.entitlements'
wsl -e bash -lc "chmod +x $wslRoot/harden.sh && bash $wslRoot/harden.sh '$wslApp' '$wslEnt'" 

# 打 zip -> ipa
Info '打包 ipa…'
$zip = [IO.Path]::ChangeExtension($stage, '.zip')
if (Test-Path $zip) { Remove-Item $zip -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($stage, $zip, [IO.Compression.CompressionLevel]::Optimal, $false)
New-Item -ItemType Directory -Force -Path (Split-Path $Out) | Out-Null
if (Test-Path $Out) { Remove-Item $Out -Force }
Move-Item $zip $Out
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue

$h = (Get-FileHash $Out -Algorithm SHA256).Hash
Ok ("已生成: $Out  (" + [math]::Round((Get-Item $Out).Length/1MB,2) + " MB)")
Write-Host ("   SHA256: " + $h)
Write-Host '   安装：把 ipa 传到 iPhone → 用 TrollStore 打开 → Install'