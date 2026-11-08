//
//  CrashLog.swift — 内置崩溃捕获（无捕获闭包版，可编译）
//  Swift 要求传给 NSSetUncaughtExceptionHandler / signal 的必须是顶层函数，不能捕获上下文
//

import Foundation
import UIKit
import Darwin

enum CrashLog {

    static var fileURL: URL {
        if let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return d.appendingPathComponent("crash.log")
        }
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("crash.log")
    }

    static func install() {
        NSSetUncaughtExceptionHandler(lyExceptionHandler)
        let signals: [Int32] = [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE, SIGTRAP]
        for s in signals {
            signal(s, lySignalHandler)
        }
    }

    static func stamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.string(from: Date())
    }

    static func threadStack() -> String {
        let count = 64
        let ptrs = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: count)
        defer { ptrs.deallocate() }
        let n = backtrace(ptrs, Int32(count))
        guard let syms = backtrace_symbols(ptrs, n) else { return "(no symbols)" }
        var out = ""
        var i = 0
        while i < Int(n) {
            if let c = syms[i] { out += String(cString: c) + "\n" }
            i += 1
        }
        free(syms)
        if out.count > 12000 { out = String(out.prefix(12000)) }
        return out
    }

    static func write(_ text: String, append: Bool) {
        let line = text.hasSuffix("\n") ? text : text + "\n"
        let url = fileURL
        if append, FileManager.default.fileExists(atPath: url.path),
           let h = try? FileHandle(forWritingTo: url) {
            h.seekToEndOfFile()
            h.write(line.data(using: .utf8) ?? Data())
            try? h.close()
            return
        }
        try? line.write(to: url, atomically: true, encoding: .utf8)
    }

    static func last() -> String {
        (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - C 函数指针（必须是无捕获的顶层函数）

func lyExceptionHandler(_ ex: NSException) {
    var stack = ex.callStackSymbols.joined(separator: "\n")
    if stack.count > 12000 { stack = String(stack.prefix(12000)) }
    let text = "==== NSException ====\ntime: \(CrashLog.stamp())\nname: \(ex.name.rawValue)\nreason: \(ex.reason ?? "")\nstep: \(StepTrace.last)\nstack:\n\(stack)\n"
    CrashLog.write(text, append: false)
}

func lySignalHandler(_ sig: Int32) {
    let text = "==== Signal ====\ntime: \(CrashLog.stamp())\nsignal: \(sig)\nstep: \(StepTrace.last)\nstack:\n\(CrashLog.threadStack())\n"
    CrashLog.write(text, append: false)
    signal(sig, SIG_DFL)
    raise(sig)
}

/// 记录最近一次操作，崩溃时一起写盘
enum StepTrace {
    private static let key = "ly.laststep"

    static func mark(_ s: String) {
        UserDefaults.standard.set("\(s) @ \(Date())", forKey: key)
    }
    static var last: String { UserDefaults.standard.string(forKey: key) ?? "" }
}
