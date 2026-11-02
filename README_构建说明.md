# LY内部 iOS（巨魔 / TrollStore）

全新 UI：**液态玻璃 · 白色调**。不做内存修改，只做**网络层拦截**（Network Extension）。
服务端完全复用 LY 现有接口（账号 / 卡密 / 云端规则），服务端**一行都不用改**。

## 目录

```
ios_ly/
├── Makefile                     # App 目标（Theos）
├── tunnel/Makefile              # 隧道扩展目标（LyTunnel.appex）
├── tunnel/LyTunnel.swift        # NEPacketTunnelProvider：按规则丢包
├── Sources/
│   ├── App.swift                # 新 UI（玻璃卡片 / 登录 / 注册 / 续期 / 规则 / 拦截）
│   ├── Api.swift                # 账号接口 + 云端规则验签解密（XOR掩码/Keychain/原生密钥）
│   ├── LyInflate.swift          # raw deflate 解压封装
│   ├── inflate_raw.c            # zlib inflateInit2(-15)
│   ├── VPN.swift                # 主 App 侧：安装/开关 VPN 配置
│   └── LyInternal-Bridging-Header.h
├── Resources/
│   ├── Info.plist               # App
│   ├── tunnel-Info.plist        # 扩展
│   └── ly_pub.pem               # 规则包 RSA 公钥（与服务器配对）
├── ly_internal.entitlements     # 巨魔 fakesign 用（含 packet-tunnel-provider）
├── harden.sh                    # 加固（strip / 明文检查 / ldid fakesign）
└── build_ipa.ps1                # Windows 侧：编译+加固+打 ipa
```

## 接口契约（与服务端一致，无需改动）

| 用途 | 请求 | 说明 |
|---|---|---|
| 注册 | `POST /a/r {user,pass,card,dev,app}` | 首次必须带卡密 |
| 登录 | `POST /a/l {user,pass,dev,app}` | 返回 `token` + `expireAt` |
| 续期 | `POST /a/s {card,dev,app}` + `X-Token` | 返回新的 `expireAt` |
| 状态 | `POST /a/m {dev,app}` + `X-Token` | 心跳（每 5 分钟） |
| 规则 | `POST /p2rL9q {dev,km,app,ver}` + `X-Token/X-Ts/X-Nonce/X-Sig` | `X-Sig = HMAC(REQ_SECRET, dev\|km\|app\|ts\|nonce)` |

规则包格式：`"LYR1" + be32(len) + 密文 + 签名(256 RSA / 32 HMAC)`
解密：`keystream: cur=SHA256(key‖"RULES") → cur=SHA256(cur‖be32(i))`，`key=SHA256(k2‖"RULES")`，`XOR → raw deflate`

## 构建（WSL + Theos）

```bash
# 1) WSL 里安装依赖
sudo apt-get update && sudo apt-get install -y make git curl ldid libplist-utils clang zlib1g-dev

# 2) 安装 Theos
export THEOS=$HOME/theos
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)" || {
  git clone --recursive https://github.com/theos/theos.git $THEOS
}

# 3) 安装 iOS SDK（在 macOS 上拷出 iPhoneOS SDK 到 $THEOS/sdks，或用 theos 的 sdk 脚本）
ls $THEOS/sdks   # 至少要有 iPhoneOS14.5.sdk 之类

# 4) 编译
cd /mnt/d/ai/ios_ly
export THEOS
make clean package
```

## 打包成 ipa（Windows 侧）

```powershell
cd D:\ai\ios_ly
.\build_ipa.ps1
# 产物: D:\ai\dist\LY内部iOS.ipa
```

## 安装（TrollStore）

1. iPhone 装好 TrollStore（iOS 14.0–16.6.1 / 17.0）
2. 把 ipa 传到手机（AirDrop / 文件 App / 局域网）
3. TrollStore → `+` → 选 ipa → Install
4. 首次点「开启网络拦截」→ 系统弹「允许 VPN 配置」→ 允许

> 巨魔会给 app 打上 `packet-tunnel-provider` 权限（fakesign），所以扩展能正常工作，不需要开发者证书。

## 加固说明

| 手段 | 实现 |
|---|---|
| 关键字符串不明文 | 服务器域名 XOR 掩码（`Srv.blob/mask`），密钥只存派生值 |
| 凭证存储 | Keychain（`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`） |
| 符号剥离 | `harden.sh` → `strip -x` |
| 免证书签名 | `ldid -S` + 自定义 entitlements |
| 规则包防篡改 | RSA-2048/SHA-256 验签（失败则只在明文可解析时降级放行） |

> 说明：iOS 上做 OLLVM 之类的控制流混淆需要自行编译 LLVM 工具链，成本高；本工程用「去符号 + 字符串掩码 + 验签」达到可接受强度。

## 能力边界（必须知道）

- ✅ 账号 / 卡密 / 续期 / 设备绑定 / 云端规则 / 规则验签
- ✅ 网络层拦截：按 **目的 IP / 网段 / 目的端口** 丢包（TCP/UDP）
- ⚠️ 域名匹配：需要解析 DNS 或 TLS SNI；当前版本只加载域名表，**未启用 SNI 解析**（下一版可加：解析 TCP 443 的 ClientHello）
- ❌ 内存修改 / 读游戏进程：iOS 无对应机制（本工程按你的要求不做）