//
//  Net.swift — 证书固定（自签证书安全信任）
//  只信任 pin 匹配的那一张证书，其余一律拒绝
//

import Foundation
import CryptoKit

final class PinnedSession: NSObject, URLSessionDelegate {

    static let shared = PinnedSession()
    static let pin = "c51a96aa5d5e704f39a1f6dd37584c27b3298762be2e6060eabd3d875e7e41df"

    lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 30
        return URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }()

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        if PinnedSession.pin.isEmpty {
            completionHandler(.useCredential, URLCredential(trust: trust))
            return
        }
        let count = SecTrustGetCertificateCount(trust)
        guard count > 0, let leaf = SecTrustGetCertificateAtIndex(trust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let der = SecCertificateCopyData(leaf) as Data
        let digest = SHA256.hash(data: der).map { String(format: "%02x", $0) }.joined()
        if digest == PinnedSession.pin {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

enum Net {
    static var session: URLSession { PinnedSession.shared.session }
}
