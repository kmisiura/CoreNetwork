import Alamofire
import Foundation
import OSLogger

enum JWTInjectorError: Error {
    case noAuthorizationToken
}

public final class JWTInjector: RequestInterceptor {
    
    private let headerFieldKey: String
    private let tokenPrefix: String?
    private let urlFilter: ((URL?) -> Bool)?
    private let reqeustModifier: Session.RequestModifier?
    
    public var authorizationToken: String?
    public var authorization401Handler: (() -> String?)?
    
    public init(headerFieldKey: String, tokenPrefix: String? = nil, urlFilter: ((URL?) -> Bool)? = nil, reqeustModifier: Session.RequestModifier? = nil) {
        self.headerFieldKey = headerFieldKey
        self.tokenPrefix = tokenPrefix
        self.urlFilter = urlFilter
        self.reqeustModifier = reqeustModifier
    }
    
    // MARK: - Request Adapter
    
    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard let token = authorizationToken else {
            Log.verbose("No authorization token.")
            completion(.failure(JWTInjectorError.noAuthorizationToken))
            return
        }
        
        var urlRequest = urlRequest
        
        if let reqeustModifier = reqeustModifier {
            Log.verbose("Running request modifier")
            try? reqeustModifier(&urlRequest)
        }
        
        guard urlFilter?(urlRequest.url) ?? true else {
            Log.verbose("Request \"\(String(describing: urlRequest.url))\" did not pass url filter.")
            completion(.success(urlRequest))
            return
        }
        
        Log.verbose("Injecting token into \(urlRequest)")
        urlRequest.setValue("\(tokenPrefix ?? "")\(token)", forHTTPHeaderField: headerFieldKey)
        completion(.success(urlRequest))
    }
    
    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        Log.verbose("error: \(error)")
        
        var shouldRetry = false
        
        if case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: let code)) = error, code == 401 {
            shouldRetry = true
        }
        
        if case AFError.requestAdaptationFailed(error: let failError) = error, JWTInjectorError.noAuthorizationToken == failError as! JWTInjectorError {
            shouldRetry = true
        }
        
        if shouldRetry {
            guard request.retryCount < 2 else {
                Log.warning("Reqeust retry failed more then 2 times. Not retrying again.")
                completion(.doNotRetry)
                return
            }
            
            guard let authorization401Handler = self.authorization401Handler else {
                Log.debug("Not retrying because no 401 handler.")
                completion(.doNotRetry)
                return
            }
            
            guard let newToken = authorization401Handler() else {
                Log.debug("Not retrying because authorization401Handler returned no new token.")
                completion(.doNotRetry)
                return
            }
            
            self.authorizationToken = newToken
            Log.debug("Retrying with new token \(newToken)")
            completion(.retry)
            return
        }
        
        Log.debug("Not calling 401 handler because error not because of invalid error.")
        completion(.doNotRetry)
    }
}
