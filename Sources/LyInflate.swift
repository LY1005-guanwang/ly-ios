import Foundation

/// raw deflate（无 zlib 头）解压，走 C 层 zlib：inflateInit2(&s, -15)
enum LyInflate {
    static func rawDeflate(_ d: Data) -> Data? {
        var outLen: Int = 0
        let p: UnsafeMutablePointer<UInt8>? = d.withUnsafeBytes { buf in
            ly_inflate_raw(buf.bindMemory(to: UInt8.self).baseAddress, d.count, &outLen)
        }
        guard let ptr = p, outLen > 0 else { return nil }
        defer { free(ptr) }
        return Data(bytes: ptr, count: outLen)
    }
}