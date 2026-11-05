//
//  LyTunnel.swift — NEPacketTunnelProvider
//  - explicit @objc name for NSExtensionPrincipalClass
//  - full logging + error propagation so the app can show the real reason
//  - packets filtered by dst IP / CIDR / port (no memory hooks)
//

import Foundation
import NetworkExtension
import Darwin

@objc(LyTunnelProvider)
final class LyTunnelProvider: NEPacketTunnelProvider {

    private var ipSet = Set<UInt32>()
    private var cidrs: [(UInt32, UInt32)] = []
    private var ports = Set<UInt16>()
    private var domains = Set<String>()
    private var keywords = [String]()

    private var blockedCount = 0
    private var totalCount = 0

    override func startTunnel(options: [String: NSObject]?,
                             completionHandler: @escaping (Error?) -> Void) {
        NSLog("[LY] startTunnel begin")
        loadRules()

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.7.0.1")
        let v4 = NEIPv4Settings(addresses: ["10.7.0.2"], subnetMasks: ["255.255.255.0"])
        v4.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = v4
        settings.dnsSettings = NEDNSSettings(servers: ["223.5.5.5", "119.29.29.29"])
        settings.mtu = 1500

        setTunnelNetworkSettings(settings) { err in
            if let e = err {
                NSLog("[LY] setTunnelNetworkSettings failed: %@", e.localizedDescription)
                completionHandler(e)
                return
            }
            NSLog("[LY] up ip=%d cidr=%d port=%d dom=%d kw=%d",
                  self.ipSet.count, self.cidrs.count, self.ports.count,
                  self.domains.count, self.keywords.count)
            completionHandler(nil)
            self.pump()
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason,
                             completionHandler: @escaping () -> Void) {
        NSLog("[LY] stop reason=%d blocked=%d/%d", reason.rawValue, blockedCount, totalCount)
        completionHandler()
    }

    private func loadRules() {
        var text = ""
        if let cfg = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration,
           let s = cfg["rules"] as? String, !s.isEmpty {
            text = s
            NSLog("[LY] rules from providerConfiguration")
        } else if let url = FileManager.default.containerURL(
                    forSecurityApplicationGroupIdentifier: "group.com.ly.neizhi.ios")?
                    .appendingPathComponent("rules.txt"),
                  let s = try? String(contentsOf: url, encoding: .utf8) {
            text = s
            NSLog("[LY] rules from app group")
        } else {
            NSLog("[LY] WARN no rules, pass all")
        }

        var sec = ""
        for raw in text.components(separatedBy: "\n") {
            let l = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if l.isEmpty { continue }
            if l.hasPrefix("#") {
                sec = String(l.dropFirst()).uppercased()
                continue
            }
            switch sec {
            case "V4":
                if l.contains("/") {
                    let p = l.split(separator: "/")
                    if p.count == 2, let ip = LyTunnelProvider.ip(String(p[0])),
                       let m = UInt32(p[1]), m <= 32 {
                        let mask: UInt32 = m == 0 ? 0 : ~UInt32(0) << (32 - m)
                        cidrs.append((ip & mask, mask))
                    }
                } else if let ip = LyTunnelProvider.ip(l) {
                    ipSet.insert(ip)
                }
            case "PORTS":
                for t in l.split(separator: ",") { if let p = UInt16(t) { ports.insert(p) } }
            case "KW":
                keywords.append(l.lowercased())
            case "DOMAINS":
                domains.insert(l.lowercased())
            default:
                break
            }
        }
    }

    private static func ip(_ s: String) -> UInt32? {
        let p = s.split(separator: ".").compactMap { UInt32($0) }
        guard p.count == 4 else { return nil }
        return (p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3]
    }

    private func pump() {
        packetFlow.readPackets { packets, _ in
            var keep: [Data] = []
            keep.reserveCapacity(packets.count)
            for p in packets {
                self.totalCount += 1
                if self.blocked(p) { self.blockedCount += 1 } else { keep.append(p) }
            }
            if !keep.isEmpty {
                self.packetFlow.writePackets(keep, withProtocols: keep.map { _ in NSNumber(value: AF_INET) })
            }
            self.pump()
        }
    }

    private func blocked(_ p: Data) -> Bool {
        guard p.count >= 20 else { return false }
        let b = [UInt8](p)
        guard (b[0] >> 4) == 4 else { return false }
        let ihl = Int(b[0] & 0x0F) * 4
        guard p.count >= ihl + 4 else { return false }
        let dst: UInt32 = (UInt32(b[16]) << 24) | (UInt32(b[17]) << 16) | (UInt32(b[18]) << 8) | UInt32(b[19])
        if ipSet.contains(dst) { return true }
        for (net, mask) in cidrs where (dst & mask) == net { return true }
        let proto = b[9]
        guard proto == 6 || proto == 17 else { return false }
        let dport = (UInt16(b[ihl + 2]) << 8) | UInt16(b[ihl + 3])
        return ports.contains(dport)
    }
}
