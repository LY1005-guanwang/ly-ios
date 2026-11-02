//
//  AntiDebug.swift — 反调试 / 反注入（不影响 TrollStore 安装）
//  注意：**不做越狱检测**，否则巨魔装不上；只挡调试器与 Frida 注入。
//

import Foundation
import Darwin

enum AntiDebug {

    /// 进程是否被调试（P_TRACED）或存在注入特征
    static var isCompromised: Bool {
        return traced() || fridaPort() || suspiciousEnv()
    }

    /// ptrace(PT_DENY_ATTACH)：让 lldb / frida 附加失败
    static func denyAttach() {
        _ = ptrace(PT_DENY_ATTACH, 0, nil, 0)
    }

    private static func traced() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        let r = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        guard r == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    /// Frida 默认监听 27042；顺带看 27043
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
            setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
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
