//
//  AntiDebug.swift — 反调试 / 反注入（不影响 TrollStore 安装）
//  只用三种手段：ptrace(PT_DENY_ATTACH) / DYLD 环境变量 / Frida 端口
//

import Foundation
import Darwin

@_silgen_name("ptrace")
private func ly_ptrace(_ request: Int32, _ pid: Int32,
                       _ addr: UnsafeMutableRawPointer?, _ data: Int32) -> Int32

enum AntiDebug {

    private static let PT_DENY_ATTACH: Int32 = 31

    static var isCompromised: Bool {
        return fridaPort() || suspiciousEnv()
    }

    /// 禁止调试器附加（lldb / frida 会 attach 失败）
    static func denyAttach() {
        _ = ly_ptrace(PT_DENY_ATTACH, 0, nil, 0)
    }

    private static func fridaPort() -> Bool {
        for port in [27042, 27043] {
            let fd = socket(AF_INET, SOCK_STREAM, 0)
            if fd < 0 { continue }
            defer { close(fd) }
            var addr = sockaddr_in()
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = UInt16(port).bigEndian
            addr.sin_addr.s_addr = inet_addr("127.0.0.1")
            var tv = timeval(tv_sec: 0, tv_usec: 200_000)
            _ = setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
            let r = withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            if r == 0 { return true }
        }
        return false
    }

    private static func suspiciousEnv() -> Bool {
        let env = ProcessInfo.processInfo.environment
        for k in ["DYLD_INSERT_LIBRARIES", "DYLD_FRAMEWORK_PATH", "FRIDA_AGENT_PATH"] {
            if let v = env[k], !v.isEmpty { return true }
        }
        return false
    }
}