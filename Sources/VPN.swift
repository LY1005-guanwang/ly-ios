//
//  VPN.swift — 纯网络层拦截（NEPacketTunnelProvider）
//  · 主 App 只负责「安装配置 / 开关」
//  · 实际过滤在扩展 LyTunnel.appex 里做（按规则表丢弃/放行出站连接）
//

import Foundation
import NetworkExtension

enum VPNController {

    static func apply(enabled: Bool, done: @escaping (String?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { list, err in
            if let e = err { done(e.localizedDescription); return }
            let mgr = (list?.first { ($0.protocolConfiguration as? NETunnelProviderProtocol)?
                        .providerBundleIdentifier == "com.ly.neizhi.ios.tunnel" }) ?? NETunnelProviderManager()
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = "com.ly.neizhi.ios.tunnel"
            proto.serverAddress = Srv.host
            // 规则文本下发到扩展（走 providerConfiguration）
            proto.providerConfiguration = [
                "rules": RuleStore.load(),
                "mode": "block"
            ]
            mgr.protocolConfiguration = proto
            mgr.localizedDescription = "LY 内部 · 网络拦截"
            mgr.isEnabled = enabled

            mgr.saveToPreferences { e1 in
                if let e = e1 { done(e.localizedDescription); return }
                mgr.loadFromPreferences { e2 in
                    if let e = e2 { done(e.localizedDescription); return }
                    if enabled {
                        do {
                            try mgr.connection.startVPNTunnel()
                            done(nil)
                        } catch { done(error.localizedDescription) }
                    } else {
                        mgr.connection.stopVPNTunnel()
                        done(nil)
                    }
                }
            }
        }
    }
}

/// 扩展侧：极简 TUN 处理 —— 按规则丢弃出站包，其余回注
final class LyTunnelProvider: NEPacketTunnelProvider {

    private var v4 = Set<String>()          // 精确 IP
    private var cidrs: [(UInt32, UInt32)] = []   // (网段, 掩码)
    private var ports = Set<UInt16>()
    private var domains = Set<String>()
    private var keywords = [String]()

    override func startTunnel(options: [String: NSObject]? = nil,
                              completionHandler: @escaping (Error?) -> Void) {
        loadRules()
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.7.0.1")
        let ipv4 = NEIPv4Settings(addresses: ["10.7.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4
        let dns = NEDNSSettings(servers: ["223.5.5.5", "119.29.29.29"])
        settings.dnsSettings = dns
        settings.mtu = 1500
        setTunnelNetworkSettings(settings) { err in
            if err == nil { self.pump() }
            completionHandler(err)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason,
                             completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    // MARK: 规则

    private func loadRules() {
        let cfg = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration
        let text = (cfg?["rules"] as? String) ?? RuleStore.load()
        var sec = ""
        for raw in text.components(separatedBy: "\n") {
            let l = raw.trimmingCharacters(in: .whitespaces)
            if l.isEmpty { continue }
            if l.hasPrefix("#") { sec = String(l.dropFirst()).uppercased(); continue }
            switch sec {
            case "V4":
                if l.contains("/") {
                    let p = l.split(separator: "/")
                    if p.count == 2, let ip = Self.ip2int(String(p[0])), let m = UInt32(p[1]) {
                        let mask: UInt32 = m == 0 ? 0 : ~UInt32(0) << (32 - m)
                        cidrs.append((ip & mask, mask))
                    }
                } else { v4.insert(l) }
            case "PORTS":
                for t in l.split(separator: ",") { if let p = UInt16(t) { ports.insert(p) } }
            case "KW":
                keywords.append(l.lowercased())
            case "DOMAINS":
                domains.insert(l.lowercased())
            default: break
            }
        }
        NSLog("[LY] rules ip=%d cidr=%d ports=%d dom=%d kw=%d",
              v4.count, cidrs.count, ports.count, domains.count, keywords.count)
    }

    private static func ip2int(_ s: String) -> UInt32? {
        let p = s.split(separator: ".").compactMap { UInt32($0) }
        guard p.count == 4 else { return nil }
        return (p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3]
    }

    // MARK: 包处理

    private func pump() {
        packetFlow.readPackets { packets, _ in
            var keep: [Data] = []
            for p in packets {
                if !self.blocked(p) { keep.append(p) }
            }
            if !keep.isEmpty {
                self.packetFlow.writePackets(keep, withProtocols: keep.map { _ in NSNumber(value: AF_INET) })
            }
            self.pump()
        }
    }

    /// 只看 IPv4 + TCP/UDP 目的地址/端口（域名匹配依赖 DNS 层，这里做端口+IP 主判）
    private func blocked(_ p: Data) -> Bool {
        guard p.count >= 20 else { return false }
        let b = [UInt8](p)
        guard (b[0] >> 4) == 4 else { return false }
        let ihl = Int(b[0] & 0x0F) * 4
        guard p.count >= ihl + 4 else { return false }
        // 目的 IP
        let dst = (UInt32(b[16]) << 24) | (UInt32(b[17]) << 16) | (UInt32(b[18]) << 8) | UInt32(b[19])
        let dstStr = "\(b[16]).\(b[17]).\(b[18]).\(b[19])"

        if v4.contains(dstStr) { return true }
        for (net, mask) in cidrs where (dst & mask) == net { return true }

        let proto = b[9]
        guard proto == 6 || proto == 17 else { return false }
        let sportOff = ihl
        guard p.count >= sportOff + 4 else { return false }
        let dport = (UInt16(b[sportOff + 2]) << 8) | UInt16(b[sportOff + 3])
        if ports.contains(dport) { return true }
        return false
    }
}
