//
//  CrashLog.swift — 内置崩溃捕获
//  - 未捕获异常 + 信号（SIGABRT/SIGSEGV/...）都写盘
//  - 下次启动在「设置」页显示，可复制
//

import Foundation
import UIKit
import Darwin

enum CrashLog {

    static var fileURL: URL {
        // 优先 Documents（TrollStore 装的应用有 no-sandbox 权限）
        if let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return d.appendingPathComponent("crash.log")
        }
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("crash.log")
    }

    static func install() {
        NSSetUncaughtExceptionHandler { ex in
            let name = ex.name.rawValue
            let reason = ex.reason ?? ""
            var stack = ex.callStackSymbols.joined(separator: "\n")
            if stack.count > 12000 { stack = String(stack.prefix(12000)) }
            write("""
            ==== NSException ====
            time: \(stamp())
            name: \(name)
            reason: \(reason)
            stack:
            \(stack)
            """, append: false)
        }

        let signals: [Int32] = [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE, SIGTRAP]
        for s in signals {
            signal(s, { sig in
                var info = "==== Signal ====\ntime: \(stamp())\nsignal: \(sig)\n"
                info += threadStack()
                write(info, append: false)
                // 恢复默认处理并重新抛出，保证系统日志也有
                signal(sig, SIG_DFL)
                raise(sig)
            })
        }
    }

    private static func stamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.string(from: Date())
    }

    private static func threadStack() -> String {
        let count = 64
        let ptrs = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: count)
        defer { ptrs.deallocate() }
        let n = backtrace(ptrs, Int32(count))
        guard let syms = backtrace_symbols(ptrs, n) else { return "(no symbols)" }
        var out = ""
        for i in 0..<Int(n) {
            if let c = syms[i] { out += String(cString: c) + "\n" }
        }
        free(syms)
        if out.count > 12000 { out = String(out.prefix(12000)) }
        return out
    }

    static func write(_ text: String, append: Bool) {
        let line = text.hasSuffix("\n") ? text : text + "\n"
        do {
            if append, FileManager.default.fileExists(atPath: fileURL.path),
               let h = try? FileHandle(forWritingTo: fileURL) {
                h.seekToEndOfFile()
                h.write(line.data(using: .utf8) ?? Data())
                try? h.close()
            } else {
                try line.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            NSLog("[LY] crash log write failed: %@", error.localizedDescription)
        }
    }

    static func last() -> String {
        (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

/// 记录最近一次「正在做的事」，崩溃时一起写下来，便于定位步骤
enum StepTrace {
    private static let key = "ly.laststep"
    static func mark(_ s: String) {
        UserDefaults.standard.set("\(s) @ \(Date())", forKey: key)
        CrashLog.write("[step] \(s)", append: true)
    }
    static var last: String { UserDefaults.standard.string(forKey: key) ?? "" }
}
