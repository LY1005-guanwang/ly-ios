#!/usr/bin/env bash
# LY 内部 iOS · 加固（在 WSL / Linux 的 Theos 环境执行）
set -e
APP="$1"
ENT="$2"
[ -d "$APP" ] || { echo "用法: ./harden.sh <LyInternal.app> [entitlements]"; exit 1; }
BIN="$APP/LyInternal"

echo "[1/6] strip 符号"
strip -x "$BIN" 2>/dev/null || true

echo "[2/6] 明文敏感串检查"
if strings -a "$BIN" | grep -Eiq '8\.163\.83\.224|c8339cf6|7edb88ca'; then
  echo "    [!] 仍有明文（Api.swift 里已做 XOR 掩码，若出现请检查是否被优化掉）"
else
  echo "    [OK] 无关键明文"
fi

echo "[3/6] 架构与 PIE 检查"
otool -hv "$BIN" | head -4 || true

echo "[4/6] fakesign（巨魔免证书）"
if command -v ldid >/dev/null 2>&1; then
  if [ -n "$ENT" ] && [ -f "$ENT" ]; then ldid -S"$ENT" "$BIN"; else ldid -S "$BIN"; fi
  if [ -d "$APP/PlugIns" ]; then
    find "$APP/PlugIns" -type f -name LyTunnel -exec ldid -S{} \; 2>/dev/null || true
  fi
  echo "    [OK] 已 fakesign"
else
  echo "    [!] 未安装 ldid：sudo apt-get install -y ldid"
fi

echo "[5/6] 权限"
chmod 755 "$BIN"

echo "[6/6] 体积"
du -sh "$APP"
echo "完成: $APP"