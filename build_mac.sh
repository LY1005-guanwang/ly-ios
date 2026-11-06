#!/bin/bash
# =====================================================================
#  LY 内部 iOS · 一键编译（任何一台 Mac 上跑）
#  用法：
#     chmod +x build_mac.sh && ./build_mac.sh
#  产物：./LY内部iOS_unsigned.ipa
#  前置：已安装 Xcode 命令行工具（脚本会自动检查并提示）
# =====================================================================
set -e

say() { printf "\n\033[1;36m[*] %s\033[0m\n" "$1"; }
ok()  { printf "\033[1;32m[OK] %s\033[0m\n" "$1"; }
err() { printf "\033[1;31m[X] %s\033[0m\n" "$1"; }

say "1/7 检查 Xcode 命令行工具"
if ! xcode-select -p >/dev/null 2>&1; then
  err "缺少 Xcode 命令行工具，请先运行： xcode-select --install"
  exit 1
fi
ok "$(xcode-select -p)"

say "2/7 安装依赖（ldid / 必要时 git）"
if ! command -v ldid >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install ldid
  else
    err "没有 Homebrew，请先装： /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
  fi
fi
ok "ldid $(command -v ldid)"

say "3/7 准备 Theos"
if [ -z "$THEOS" ] || [ ! -d "$THEOS" ]; then
  export THEOS="$HOME/theos"
fi
if [ ! -d "$THEOS" ]; then
  git clone --recursive --depth 1 https://github.com/theos/theos.git "$THEOS"
fi
export PATH="$THEOS/bin:$PATH"

say "4/7 下载 iOS SDK"
mkdir -p "$THEOS/sdks"
if ! ls "$THEOS"/sdks/*.sdk >/dev/null 2>&1; then
  curl -L --retry 3 https://github.com/theos/sdks/archive/refs/heads/master.tar.gz -o /tmp/sdks.tgz
  tar xzf /tmp/sdks.tgz -C /tmp
  cp -R /tmp/sdks-master/*.sdk "$THEOS/sdks/" || true
fi
ok "SDK: $(ls "$THEOS"/sdks | tr '\n' ' ')"

say "5/7 编译主程序 + 隧道扩展"
make clean all -j4
( cd tunnel && make clean all -j4 )

say "6/7 组装 Payload"
APP=$(find . -maxdepth 6 -type d -name "LyInternal.app" | head -1)
APPEX=$(find . -maxdepth 6 -type d -name "LyTunnel.appex" | head -1)
[ -n "$APP" ] || { err "找不到 LyInternal.app"; exit 1; }
rm -rf Payload LY内部iOS_unsigned.ipa
mkdir -p Payload
cp -R "$APP" Payload/
rm -rf Payload/LyInternal.app/_CodeSignature Payload/LyInternal.app/CodeResources 2>/dev/null || true
mkdir -p Payload/LyInternal.app/PlugIns
[ -n "$APPEX" ] && cp -R "$APPEX" Payload/LyInternal.app/PlugIns/

APPDIR="Payload/LyInternal.app"
APPEXDIR="$APPDIR/PlugIns/LyTunnel.appex"
if [ -d "$APPEXDIR" ]; then
  cp Resources/tunnel-Info.plist "$APPEXDIR/Info.plist"
  rm -f "$APPEXDIR/LyInternal" "$APPEXDIR/ly_pub.pem" 2>/dev/null || true
  rm -rf "$APPEXDIR/_CodeSignature"
fi
[ -f Resources/ly_pub.pem ] && cp Resources/ly_pub.pem "$APPDIR/"
chmod 755 "$APPDIR/LyInternal"

say "7/7 注入 entitlements（VPN + GPU）并打包"
ldid -Sly_internal.entitlements "$APPDIR/LyInternal"
[ -d "$APPEXDIR" ] && { chmod 755 "$APPEXDIR/LyTunnel"; ldid -Sly_internal.entitlements "$APPEXDIR/LyTunnel"; }

echo "--- entitlements (app) ---"
ldid -e "$APPDIR/LyInternal"
[ -d "$APPEXDIR" ] && { echo "--- entitlements (appex) ---"; ldid -e "$APPEXDIR/LyTunnel"; }

zip -qr LY内部iOS_unsigned.ipa Payload

ok "完成：$(pwd)/LY内部iOS_unsigned.ipa  ($(du -h LY内部iOS_unsigned.ipa | cut -f1))"
echo
echo "安装：把这个 ipa 传到手机 → TrollStore → + → 选择安装"
