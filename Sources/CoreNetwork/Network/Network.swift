import Alamofire
import Combine
import Foundation
import OSLogger

public class Network<T: Decodable>: GenericNetwork {
    
    public init(endPoint: String,
                decoder: JSONDecoder = JSONDecoder(),
                encoding: ParameterEncoding = JSONEncoding.default,
                session: Session? = nil,
                enableCaching: Bool? = nil,
                requestInterceptor: RequestInterceptor? = nil,
                headers: [String: String]? = nil,
                errorMapper: NetworkErrorMapper? = nil) {
        var name = "\(endPoint)_\(T.self)"
        name.unicodeScalars.removeAll(where: { !CharacterSet.urlUserAllowed.contains($0) })
        
        super.init(endPoint: endPoint,
                   decoder: decoder,
                   encoding: encoding,
                   session: session,
                   enableCaching: enableCaching,
                   requestInterceptor: requestInterceptor,
                   headers: headers,
                   errorMapper: errorMapper,
                   name: name)
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
                         parameters: [String: Any]? = nil,
                         item: [String: Any]? = nil,
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
                           parameters: [String: Any]? = nil,
                           item: [String: Any]? = nil,
                           validStatusCodes: Range<Int> = 200..<300) -> AnyPublisher<T?, CoreNetworkError> {
        return publisherForOptionalPath(path,
                                        method: .delete,
                                        parameters: parameters,
                                        item: item,
                                        validStatusCodes: validStatusCodes)
    }
}
