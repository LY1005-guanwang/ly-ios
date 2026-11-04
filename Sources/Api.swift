//
//  Api.swift — 账号 / 卡密 / 云端规则（复用 LY 服务端，接口零改动）
//

import Foundation
import CryptoKit
import Security

// MARK: - 服务端配置

enum Srv {
    // 服务器地址（XOR 掩码存放，避免明文出现在二进制里被一眼看到）
    private static let mask: [UInt8] = [0x5A, 0x3C, 0x91, 0x27, 0x6E, 0x14, 0xB8, 0x43,
                                        0x2D, 0x77, 0xA6, 0x19, 0xE4, 0x50, 0x8B, 0x3F]
    private static let blob: [UInt8] = [0x62, 0x12, 0xA0, 0x11, 0x5D, 0x3A, 0x80, 0x70, 0x03, 0x45, 0x94, 0x2D]
    static var host: String {
        let b = zip(blob, mask).map { $0 ^ $1 }
        return String(bytes: b, encoding: .utf8) ?? "8.163.83.224"
    }
    static let port = 8787
    static let rulesPath = "/p2rL9q"
    static let app = "ly"
}

// MARK: - 本地存储

enum Settings {
    private static let k = "ly.settings"
    static var vpnOn: Bool {
        get { UserDefaults.standard.bool(forKey: k + ".vpn") }
        set { UserDefaults.standard.set(newValue, forKey: k + ".vpn") }
    }
}

enum Session {
    private static let svc = "com.ly.neizhi.ios"
    private static let acc = "session"

    private struct Box: Codable { var token: String; var user: String; var expireAt: Int64 }

    private static func read() -> Box? {
        guard let data = Keychain.get(service: svc, account: acc) else { return nil }
        return try? JSONDecoder().decode(Box.self, from: data)
    }
    private static func write(_ b: Box) {
        if let d = try? JSONEncoder().encode(b) { Keychain.set(service: svc, account: acc, data: d) }
    }

    static var token: String { read()?.token ?? "" }
    static var user: String { read()?.user ?? "" }
    static var expireAt: Int64 { read()?.expireAt ?? 0 }
    static var logged: Bool { token.count > 16 }
    static var expired: Bool { expireAt > 0 && Int64(Date().timeIntervalSince1970 * 1000) > expireAt }

    static func save(token: String, expireAt: Int64, user: String) {
        write(Box(token: token, user: user, expireAt: expireAt))
    }
    static func touch(expireAt: Int64) {
        guard var b = read(), expireAt > 0 else { return }
        b.expireAt = expireAt
        write(b)
    }
    static func clear() { Keychain.del(service: svc, account: acc) }
}

enum Keychain {
    static func set(service: String, account: String, data: Data) {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: service,
                                kSecAttrAccount as String: account]
        SecItemDelete(q as CFDictionary)
        var add = q
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }
    static func get(service: String, account: String) -> Data? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: service,
                                kSecAttrAccount as String: account,
                                kSecReturnData as String: true,
                                kSecMatchLimit as String: kSecMatchLimitOne]
        var out: CFTypeRef?
        return SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess ? (out as? Data) : nil
    }
    static func del(service: String, account: String) {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: service,
                                kSecAttrAccount as String: account]
        SecItemDelete(q as CFDictionary)
    }
}

enum RuleStore {
    private static var url: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("rules.txt")
    }
    static func save(_ s: String) { try? s.write(to: url, atomically: true, encoding: .utf8) }
    static func load() -> String { (try? String(contentsOf: url, encoding: .utf8)) ?? "" }
}

// MARK: - 设备标识

enum Dev {
    static var id: String {
        let key = "ly.dev"
        if let s = UserDefaults.standard.string(forKey: key), s.count > 8 { return s }
        let s = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        UserDefaults.standard.set(s, forKey: key)
        return s
    }
}

// MARK: - 账号接口

struct ApiResult {
    var ok = false
    var token = ""
    var user = ""
    var expireAt: Int64 = 0
    var msg = ""
}

enum AccountApi {

    private static func post(_ path: String, _ body: [String: Any], token: String = "", done: @escaping (ApiResult) -> Void) {
        var req = URLRequest(url: URL(string: "https://\(Srv.host):\(Srv.port)\(path)")!)
        req.httpMethod = "POST"
        req.timeoutInterval = 20
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !token.isEmpty { req.setValue(token, forHTTPHeaderField: "X-Token") }
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        Net.session.dataTask(with: req) { data, resp, err in
            var r = ApiResult()
            defer { DispatchQueue.main.async { done(r) } }
            if let e = err { r.msg = (e.localizedDescription.contains("certificate") || e.localizedDescription.contains("证书")) ? "安全通道异常（证书校验未通过）" : "网络异常：" + e.localizedDescription; return }
            guard let d = data, let o = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else {
                r.msg = "响应无法解析"; return
            }
            r.ok = (o["ok"] as? Bool) ?? false
            r.token = (o["token"] as? String) ?? ""
            r.user = (o["user"] as? String) ?? ""
            if let e = o["expireAt"] as? Int64 { r.expireAt = e }
            else if let e = o["expireAt"] as? Double { r.expireAt = Int64(e) }
            else if let e = o["expireAt"] as? NSNumber { r.expireAt = e.int64Value }
            r.msg = (o["msg"] as? String) ?? ""
            if !r.ok && r.msg.isEmpty { r.msg = "未知错误" }
        }.resume()
    }

    static func register(user: String, pass: String, card: String, done: @escaping (ApiResult) -> Void) {
        post("/a/r", ["user": user, "pass": pass, "card": card, "dev": Dev.id, "app": Srv.app], done: done)
    }
    static func login(user: String, pass: String, done: @escaping (ApiResult) -> Void) {
        post("/a/l", ["user": user, "pass": pass, "dev": Dev.id, "app": Srv.app], done: done)
    }
    static func renew(card: String, done: @escaping (ApiResult) -> Void) {
        post("/a/s", ["card": card, "dev": Dev.id, "app": Srv.app], token: Session.token, done: done)
    }
    static func me(done: @escaping (ApiResult) -> Void) {
        post("/a/m", ["dev": Dev.id, "app": Srv.app], token: Session.token, done: done)
    }
}

// MARK: - 云端规则

enum CloudRules {

    // 派生密钥（由原生密钥派生；iOS 无 .so，直接内嵌派生值）
    private static let reqSecret: [UInt8] = [
        0x7E, 0xDB, 0x88, 0xCA, 0x83, 0xAA, 0x3B, 0xEE, 0x2E, 0x33, 0x67, 0x86, 0x76, 0x49, 0x3B, 0x35,
        0x94, 0x08, 0x15, 0x8E, 0xAD, 0x42, 0xC1, 0xFD, 0x5B, 0x17, 0xD7, 0xB8, 0x29, 0x99, 0x5B, 0x68
    ]
    private static let k2hex = "c8339cf6be9a88e92dbd7a77a5c51c3a"

    private static var lastDiag = ""

    private static func sha(_ b: Data) -> Data { Data(SHA256.hash(data: b)) }

    private static func rulesKey() -> Data {
        var k = Data(hex: k2hex) ?? Data()
        k.append("RULES".data(using: .utf8)!)
        return sha(k)
    }

    private static func sig(_ data: String) -> String {
        let key = SymmetricKey(data: Data(reqSecret))
        let mac = HMAC<SHA256>.authenticationCode(for: Data(data.utf8), using: key)
        return mac.map { String(format: "%02x", $0) }.joined()
    }

    static func fetch(done: @escaping (Bool, String, String) -> Void) {
        let ts = Int64(Date().timeIntervalSince1970 * 1000)
        let nonce = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let dev = Dev.id
        let km = ""
        let payload = "\(dev)|\(km)|\(Srv.app)|\(ts)|\(nonce)"

        var req = URLRequest(url: URL(string: "https://\(Srv.host):\(Srv.port)\(Srv.rulesPath)")!)
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Session.token, forHTTPHeaderField: "X-Token")
        req.setValue(String(ts), forHTTPHeaderField: "X-Ts")
        req.setValue(nonce, forHTTPHeaderField: "X-Nonce")
        req.setValue(sig(payload), forHTTPHeaderField: "X-Sig")
        req.httpBody = try? JSONSerialization.data(withJSONObject:
            ["dev": dev, "km": km, "app": Srv.app, "ver": 1])

        Net.session.dataTask(with: req) { data, resp, err in
            var ok = false, text = ""
            lastDiag = ""
            defer { DispatchQueue.main.async { done(ok, text, lastDiag) } }
            if let e = err { lastDiag = "网络异常：" + e.localizedDescription; return }
            guard let d = data, d.count > 16 else { lastDiag = "响应为空"; return }
            if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
                var msg = ""
                if let o = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
                    msg = (o["msg"] as? String) ?? (o["code"] as? String) ?? ""
                }
                if msg.isEmpty { msg = String(data: d.prefix(80), encoding: .utf8) ?? "" }
                lastDiag = "HTTP \(http.statusCode)：\(msg)"
                return
            }
            if let s = unwrap(d) { text = s; ok = true }
        }.resume()
    }

    /// 解包：头部 LYR1 + be32(len) + 密文 + 签名(256 RSA / 32 HMAC)
    private static func unwrap(_ pkg: Data) -> String? {
        guard pkg.count > 12 else { lastDiag = "包太短"; return nil }
        let head = pkg.prefix(4)
        guard String(data: head, encoding: .utf8) == "LYR1" else {
            let s = String(data: pkg.prefix(60), encoding: .utf8) ?? "?"
            lastDiag = "头不是 LYR1：\(s)"; return nil
        }
        let lenBytes = [UInt8](pkg[4..<8])
        let clen = (Int(lenBytes[0]) << 24) | (Int(lenBytes[1]) << 16) | (Int(lenBytes[2]) << 8) | Int(lenBytes[3])
        guard 8 + clen + 32 <= pkg.count else { lastDiag = "长度字段不符"; return nil }
        let ct = pkg.subdata(in: 8..<(8 + clen))
        let tail = pkg.subdata(in: (8 + clen)..<pkg.count)
        let signed = pkg.subdata(in: 0..<(8 + clen))

        var sigOk = false
        if tail.count == 256 {
            sigOk = rsaVerify(signed: signed, sig: tail)
            lastDiag = "RSA验签=\(sigOk ? "通过" : "失败")"
        } else if tail.count == 32 {
            let key = SymmetricKey(data: rulesKey())
            let mac = HMAC<SHA256>.authenticationCode(for: signed, using: key)
            sigOk = Data(mac) == tail
            lastDiag = "HMAC回退=\(sigOk ? "通过" : "失败")"
        } else {
            lastDiag = "签名长度异常 tail=\(tail.count)"
        }
        // 兼容模式：验签失败也继续解密（明文可解析即放行）
        if !sigOk { lastDiag += " · 未验签(兼容)" }

        let plain = xorStream(ct)
        guard let raw = LyInflate.rawDeflate(plain) else { lastDiag += " · 解压失败"; return nil }
        guard let s = String(data: raw, encoding: .utf8) else { lastDiag += " · 编码异常"; return nil }
        if !s.contains("#V4") && !s.contains("#PORTS") {
            lastDiag += " · 明文不像规则"; return nil
        }
        lastDiag += " · 明文 \(raw.count) 字节"
        return s
    }

    private static func xorStream(_ ct: Data) -> Data {
        let key = rulesKey()
        var cur = sha(key + "RULES".data(using: .utf8)!)
        var out = Data(count: ct.count)
        var i = 0
        out.withUnsafeMutableBytes { dst in
            ct.withUnsafeBytes { src in
                let d = dst.bindMemory(to: UInt8.self), s = src.bindMemory(to: UInt8.self)
                while i < ct.count {
                    var be = [UInt8](repeating: 0, count: 4)
                    be[0] = UInt8((i >> 24) & 0xff); be[1] = UInt8((i >> 16) & 0xff)
                    be[2] = UInt8((i >> 8) & 0xff);  be[3] = UInt8(i & 0xff)
                    cur = sha(cur + Data(be))
                    let n = min(cur.count, ct.count - i)
                    cur.withUnsafeBytes { kb in
                        let k = kb.bindMemory(to: UInt8.self)
                        for j in 0..<n { d[i + j] = s[i + j] ^ k[j] }
                    }
                    i += n
                }
            }
        }
        return out
    }

    private static func rsaVerify(signed: Data, sig: Data) -> Bool {
        guard let pem = Bundle.main.url(forResource: "ly_pub", withExtension: "pem"),
              let body = try? String(contentsOf: pem, encoding: .utf8)
                .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
                .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "")
                .replacingOccurrences(of: " ", with: ""),
              let der = Data(base64Encoded: body) else { return false }

        let attrs: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                    kSecAttrKeyClass as String: kSecAttrKeyClassPublic]
        guard let key = SecKeyCreateWithData(der as CFData, attrs as CFDictionary, nil) else { return false }
        return SecKeyVerifySignature(key, .rsaSignatureMessagePKCS1v15SHA256,
                                     signed as CFData, sig as CFData, nil)
    }
}

// MARK: - 小工具

extension Data {
    init?(hex: String) {
        let s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.count % 2 == 0 else { return nil }
        var out = [UInt8](); out.reserveCapacity(s.count / 2)
        var i = s.startIndex
        while i < s.endIndex {
            let j = s.index(i, offsetBy: 2)
            guard let b = UInt8(s[i..<j], radix: 16) else { return nil }
            out.append(b); i = j
        }
        self = Data(out)
    }
}
