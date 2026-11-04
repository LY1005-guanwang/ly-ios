import Foundation

/// 解压：先 raw deflate（服务端 deflateRawSync），不行再试 zlib 包装
enum LyInflate {

    static func rawDeflate(_ d: Data) -> Data? {
        if let out = run(d, raw: true) { return out }
        return run(d, raw: false)
    }

    private static func run(_ d: Data, raw: Bool) -> Data? {
        var outLen: Int = 0
        let p: UnsafeMutablePointer<UInt8>? = d.withUnsafeBytes { buf in
            let base = buf.bindMemory(to: UInt8.self).baseAddress
            return raw
                ? ly_inflate_raw(base, d.count, &outLen)
                : ly_inflate_zlib(base, d.count, &outLen)
        }
        guard let ptr = p, outLen > 0 else { return nil }
        defer { free(ptr) }
        return Data(bytes: ptr, count: outLen)
    }
}
