import Foundation
import SwiftCrypto
import OSLogger

public struct SigV3 {
    let appId: String
    let signingKey: [UInt8]
    
    public init(appId: String, signingKey: [UInt8]) {
        self.appId = appId
        self.signingKey = signingKey
    }
    
    func decoded() -> [UInt8] {
        return signingKey.map { $0 ^ 0xcc }
    }
}

internal extension SigV3 {
    struct DefaultKeys {
        static let appID = "appid"
        static let signatureVersion = "3"
        static let signatureHeader = "Sig"
        static let timeHeader = "SigT"
        static let versionHeader = "SigV"
    }
}

public extension SigV3 {
    
    enum Error: Swift.Error {
        case missingRequestUrl
        case badRequestUrl
    }
    
    func adapt(request: inout URLRequest, time: String? = nil) throws -> Void {
        guard let url = request.url else {
            Log.debug("Cannot adapt request with no URL")
            throw Error.missingRequestUrl
        }
        
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Log.debug("Failed to generate URLComponenets from \(url)")
            throw Error.badRequestUrl
        }
        
        var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
        if !queryItems.contains(where: { $0.name == DefaultKeys.appID }) {
            queryItems.append(URLQueryItem(name: DefaultKeys.appID, value: appId))
        }
        urlComponents.queryItems = queryItems
        
        guard let signingUrl = urlComponents.url else {
            Log.debug("Failed to generate signed URL from \(urlComponents)")
            throw Error.badRequestUrl
        }
        
        let time = time ?? String(Int64(Date().timeIntervalSince1970))
        let signingPath = "\(urlComponents.path)?\(signingUrl.query ?? "")\(DefaultKeys.signatureVersion)\(time)".bytesArray
        let secret = self.decoded()
        
        let payload = signingPath + (request.httpBody ?? Data())
        let signature = Data(payload).digest(.sha1, key: Data(secret)).hexEncodedString()
        
        request.addValue(DefaultKeys.signatureVersion, forHTTPHeaderField: DefaultKeys.versionHeader)
        request.addValue(time, forHTTPHeaderField: DefaultKeys.timeHeader)
        request.addValue(signature, forHTTPHeaderField: DefaultKeys.signatureHeader)
    }
}
