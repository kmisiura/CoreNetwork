import Alamofire
import Foundation
import OSLogger

public final class SigV3Injector: RequestInterceptor {
    
    private let urlFilter: ((URL?) -> Bool)?
    private let signature: SigV3
    
    public init(signature: SigV3, urlFilter: ((URL?) -> Bool)? = nil) {
        self.signature = signature
        self.urlFilter = urlFilter
    }
    
    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        
        guard urlFilter?(urlRequest.url) ?? true else {
            Log.verbose("Request \"\(String(describing: urlRequest.url))\" did not pass url filter.")
            completion(.success(urlRequest))
            return
        }
        
        Log.verbose("Injecting ZSigV3 into \(urlRequest)")
        var urlRequest = urlRequest
        do {
            try signature.adapt(request: &urlRequest)
            completion(.success(urlRequest))
        } catch {
            completion(.failure(error))
        }
    }
}
