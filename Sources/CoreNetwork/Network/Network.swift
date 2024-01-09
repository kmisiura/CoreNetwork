import Alamofire
import Combine
import Foundation
import OSLogger

public class Network<T: Decodable>: GenericNetwork {
    
    public init(endPoint: String,
                decoder: JSONDecoder = JSONDecoder(),
                encoding: ParameterEncoding = JSONEncoding.default,
                session: Session = newDefaultSession(),
                requestModifier: Session.RequestModifier? = nil,
                requestInterceptor: RequestInterceptor? = nil,
                headers: [String: String]? = nil) {
        
        super.init(endPoint: endPoint,
                   decoder: decoder,
                   encoding: encoding,
                   session: session,
                   requestModifier: requestModifier,
                   requestInterceptor: requestInterceptor,
                   headers: headers)
    }
    
    // MARK: - Public functions
    
    public func getItem(_ path: String,
                        parameters: [String: Any]? = nil,
                        validStatusCodes: Range<Int> = 200..<300) -> AnyPublisher<T, CoreNetworkError> {
        return publisherForPath(path,
                                method: .get,
                                parameters: parameters,
                                validStatusCodes: validStatusCodes)
    }
    
    public func getItems(_ path: String,
                         parameters: [String: Any]? = nil,
                         validStatusCodes: Range<Int> = 200..<300) -> AnyPublisher<[T], CoreNetworkError> {
        return publisherForPath(path,
                                method: .get,
                                parameters: parameters,
                                validStatusCodes: validStatusCodes)
    }
    
    public func postItem(_ path: String,
                         parameters: [String: Any],
                         item: [String: Any],
                         validStatusCodes: Range<Int> = 200..<300) -> AnyPublisher<T?, CoreNetworkError> {
        return publisherForOptionalPath(path,
                                        method: .post,
                                        parameters: parameters,
                                        item: item,
                                        validStatusCodes: validStatusCodes)
    }
    
    public func putItem(_ path: String,
                        parameters: [String: Any],
                        item: [String: Any],
                        validStatusCodes: Range<Int> = 200..<300) -> AnyPublisher<T?, CoreNetworkError> {
        return publisherForOptionalPath(path,
                                        method: .put,
                                        parameters: parameters,
                                        item: item,
                                        validStatusCodes: validStatusCodes)
    }
    
    public func deleteItem(_ path: String,
                           parameters: [String: Any],
                           item: [String: Any],
                           validStatusCodes: Range<Int> = 200..<300) -> AnyPublisher<T?, CoreNetworkError> {
        return publisherForOptionalPath(path,
                                        method: .delete,
                                        parameters: parameters,
                                        item: item,
                                        validStatusCodes: validStatusCodes)
    }
}
