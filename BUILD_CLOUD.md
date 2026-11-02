# 编译 iOS 版：三条路 + 下载链接

## 结论先说

**这台机器编不了**：没有 macOS / Xcode，也没装 WSL 发行版，连 clang、git 都没有。
iOS 的 arm64 二进制必须在 **macOS 工具链**下产出。三条路，按推荐排序：

---

## 方案 A（推荐 · 免费 · 不需要 Mac）GitHub Actions 云编译

工程里已经放好 `.github/workflows/build.yml`，推到 GitHub 就自动出 ipa。

需要注册/下载：

| 东西 | 链接 |
|---|---|
| GitHub 账号 | https://github.com/signup |
| GitHub Desktop（可选，图形化上传） | https://desktop.github.com/ |
| Git for Windows（上传用） | https://git-scm.com/download/win |

流程：
```powershell
cd D:\ai\ios_ly
git init
git add .
git commit -m "ios ly"
git branch -M main
git remote add origin https://github.com/<你的账号>/ly-ios.git
git push -u origin main
```
→ 打开仓库 **Actions** 标签 → `build-ipa` 跑完 → 下载 `LyInternal-ipa`（就是 ipa）。

> 免费额度：公开仓库 **完全免费**；私有仓库每月 2000 分钟（一次构建约 8–12 分钟）。
> macOS runner 自带 Xcode，所以 **Swift 也能编**（Theos 在 macOS 上支持 swiftc）。

---

## 方案 B（有 Mac / 借 Mac 10 分钟）Xcode + Theos 本地编

| 东西 | 链接 |
|---|---|
| Xcode（App Store 或开发者站） | https://developer.apple.com/xcode/ |
| Xcode Command Line Tools | `xcode-select --install` |
| Theos | https://github.com/theos/theos |
| Theos 官方 iOS SDK 集合 | https://github.com/theos/sdks |
| ldid（fakesign 用） | https://github.com/ProcursusTeam/ldid |

```bash
git clone --recursive https://github.com/theos/theos.git ~/theos
export THEOS=~/theos
curl -L https://github.com/theos/sdks/archive/refs/heads/master.tar.gz | tar xz -C /tmp
cp -R /tmp/sdks-master/*.sdk ~/theos/sdks/
cd /path/to/ios_ly && make package
# 然后用 build_ipa.ps1 的逻辑（或直接 zip Payload）打包
```

---

## 方案 C（Windows 本地 · 要改代码）WSL + Theos

| 东西 | 链接 |
|---|---|
| WSL 安装说明 | https://learn.microsoft.com/windows/wsl/install |
| Ubuntu 22.04（商店） | https://apps.microsoft.com/detail/9pdxgncfsczv |
| Theos Linux 依赖说明 | https://theos.dev/docs/installation-linux |
| Theos 源码 | https://github.com/theos/theos |
| Theos iOS SDK | https://github.com/theos/sdks |
| ldid | `sudo apt install ldid`（或 https://github.com/ProcursusTeam/ldid ） |

一键命令（**管理员 PowerShell**，装完要重启）：
```powershell
wsl --install -d Ubuntu-22.04
```
装好后再进 Ubuntu：
```bash
sudo apt update && sudo apt install -y make git curl zip ldid libplist-utils clang zlib1g-dev
git clone --recursive https://github.com/theos/theos.git ~/theos
export THEOS=~/theos
curl -L https://github.com/theos/sdks/archive/refs/heads/master.tar.gz | tar xz -C /tmp
mkdir -p ~/theos/sdks && cp -R /tmp/sdks-master/*.sdk ~/theos/sdks/
cd /mnt/d/ai/ios_ly && make clean package
```

> ⚠️ **Linux 上 Theos 只能编 Objective-C/C**：Swift 编译 iOS 依赖 Apple 的 Swift 工具链（仅 macOS 提供）。
> 所以方案 C 需要我把工程**改写成 Objective-C**（约 800 行，我能做，说一声）。

---

## 装到手机

| 东西 | 链接 |
|---|---|
| TrollStore（巨魔） | https://github.com/opa334/TrollStore |
| TrollStore 安装指南 | https://ios.cfw.guide/installing-trollstore/ |

装法：把 ipa 传到手机 → TrollStore → `+` → 选 ipa → Install → 首次开拦截时点「允许 VPN 配置」。

---

## 加固可选（想更强再用）

| 工具 | 链接 | 用途 |
|---|---|---|
| OLLVM（控制流平坦化） | https://github.com/obfuscator-llvm/obfuscator | 需自编 LLVM，成本高 |
| ldid | https://github.com/ProcursusTeam/ldid | fakesign + entitlements |
| SwiftShield（Swift 符号混淆） | https://github.com/rockbruno/SwiftShield | 混淆类名/方法名 |

---

## 我的建议

**走方案 A**：不装任何东西，注册个 GitHub 账号，把 `D:\ai\ios_ly` 推上去，8 分钟拿到 ipa。
要我现在就把「推送命令 + 仓库初始化」再简化（比如给你一个双击运行的 `push_to_github.ps1`），说一声。