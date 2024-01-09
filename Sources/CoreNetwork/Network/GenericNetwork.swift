import Alamofire
import Combine
import Foundation
import OSLogger


public protocol NetworkErrorMapper {
    /// Parses backend response in case of error status codes and converts it to an `Error'`
    ///
    /// - Parameters:
    ///   - decoder:    `JSONDecoder` which should be used to parse server response.
    ///   - statusCode: Status code returned from the server.
    ///   - data:       `Data` returned from the server.
    ///
    /// - Returns:    The `Error` parsed from the response or nil.
    func map(decoder: JSONDecoder, statusCode: Int, data: Data) -> Error?
}

public class GenericNetwork {
    
    private let endPoint: String
    private let encoding: ParameterEncoding
    private let decoder: JSONDecoder
    private let decoderQueue = DispatchQueue.global(qos: .userInitiated)
    private let requestModifier: Session.RequestModifier?
    private let requestInterceptor: RequestInterceptor?
    private let errorMapper: NetworkErrorMapper?
    
    internal let session: Session
    
    /**
     Additional header fields to use in all reqeust.
     
     These are a network scope fields and will be used for all request coming from this network.
     
     - Important: These header fields will override `Settings.globalHeaderFields`.
     */
    public var headerFields: [String: String] = [:]
    
    /**
     Additional query items to use in all reqeust.
     
     These are a network scope query items and will be used for all request coming from this network.
     
     - Important: These query items will override `Settings.globalQueryItems` and will be overriden by reuqests parameters.
     */
    public var queryItems: [String: Any] = [:]

    public static func newDefaultSession() -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 9
        configuration.timeoutIntervalForResource = 9
        let session = Session(configuration: configuration)
        return session
    }
    
    public init(endPoint: String,
                decoder: JSONDecoder = JSONDecoder(),
                encoding: ParameterEncoding = JSONEncoding.default,
                session: Session = newDefaultSession(),
                requestModifier: Session.RequestModifier? = nil,
                requestInterceptor: RequestInterceptor? = nil,
                headers: [String: String]? = nil,
                errorMapper: NetworkErrorMapper? = nil) {
        self.endPoint = endPoint
        self.decoder = decoder
        self.encoding = encoding
        self.session = session
        self.requestModifier = requestModifier
        self.requestInterceptor = requestInterceptor
        self.errorMapper = errorMapper
        self.headerFields = headers ?? [:]
    }
    
    // MARK: - Public functions
    
    /// Returns publisher for provided API path.
    ///
    /// - Parameters:
    ///   - path:               `String` that specifies API path.
    ///   - method:             `HTTPMethod` for the request.
    ///   - parameters:         Url parameters.
    ///   - requestInterceptor: `RequestInterceptor` to use for the request
    ///   - validStatusCodes:   `Range` of the status codes when response is treated as a success.
    ///
    /// - Returns:    The `AnyPublisher<R, CoreNetworkError>`.
    public func publisherForPath<R: Decodable>(_ path: String,
                                               method: HTTPMethod = .get,
                                               parameters: [String: Any]? = nil,
                                               requestInterceptor: RequestInterceptor? = nil,
                                               validStatusCodes: Range<Int> = 200..<300) -> AnyPublisher<R, CoreNetworkError> {
        let url = generateURLFrom(path: path, parameters: parameters)
        return Just(())
            .setFailureType(to: CoreNetworkError.self)
            .flatMap {
                self.session.request(url,
                                     method: method,
                                     encoding: self.encoding,
                                     headers: self.makeHeaderFields(),
                                     interceptor: requestInterceptor ?? self.requestInterceptor,
                                     requestModifier: self.requestModifier)
                .logRequest()
                .validate(statusCode: validStatusCodes)
                .publishDecodable(type: R.self)
                .tryMap { result -> R in try self.validateResult(result) }
                .mapError { $0 as? CoreNetworkError ?? CoreNetworkError.network(error: $0) }
                .eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }
    
    /// Returns publisher for provided API path.
    ///
    /// - Parameters:
    ///   - path:               `String` that specifies API path.
    ///   - method:             `HTTPMethod` for the request.
    ///   - parameters:         Url parameters.
    ///   - item:               Body parameters.
    ///   - requestInterceptor: `RequestInterceptor` to use for the request
    ///   - validStatusCodes:   `Range` of the status codes when response is treated as a success.
    ///
    /// - Returns:    The `AnyPublisher<R, CoreNetworkError>`.
    public func publisherForPath<R: Decodable>(_ path: String,
                                               method: HTTPMethod = .get,
                                               parameters: [String: Any]? = nil,
                                               item: [String: Any]? = nil,
                                               requestInterceptor: RequestInterceptor? = nil,
                                               validStatusCodes: Range<Int> = 200..<300) -> AnyPublisher<R, CoreNetworkError> {
        let url = generateURLFrom(path: path, parameters: parameters)
        return Just(())
            .setFailureType(to: CoreNetworkError.self)
            .flatMap {
                self.session.request(url,
                                     method: method,
                                     parameters: item,
                                     encoding: self.encoding,
                                     headers: self.makeHeaderFields(),
                                     interceptor: requestInterceptor ?? self.requestInterceptor,
                                     requestModifier: self.requestModifier)
                .logRequest()
                .validate(statusCode: validStatusCodes)
                .publishDecodable(type: R.self)
                .tryMap { result -> R in
                    try self.validateResult(result)
                }
                .mapError { $0 as? CoreNetworkError ?? CoreNetworkError.network(error: $0) }
                .eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }
    
    /// Returns publisher for provided API path with optional result.
    ///
    /// - Parameters:
    ///   - path:               `String` that specifies API path.
    ///   - method:             `HTTPMethod` for the request.
    ///   - parameters:         Url parameters.
    ///   - item:               Body parameters.
    ///   - requestInterceptor: `RequestInterceptor` to use for the request
    ///   - validStatusCodes:   `Range` of the status codes when response is treated as a success.
    ///
    /// - Returns:    The `AnyPublisher<R?, CoreNetworkError>`.
    public func publisherForOptionalPath<R: Decodable>(_ path: String,
                                                       method: HTTPMethod = .get,
                                                       parameters: [String: Any]? = nil,
                                                       item: [String: Any]? = nil,
                                                       requestInterceptor: RequestInterceptor? = nil,
                                                       validStatusCodes: Range<Int> = 200..<300) -> AnyPublisher<R?, CoreNetworkError> {
        let url = generateURLFrom(path: path, parameters: parameters)
        return Just(())
            .setFailureType(to: CoreNetworkError.self)
            .flatMap {
                self.session.request(url,
                                     method: method,
                                     parameters: item,
                                     encoding: self.encoding,
                                     headers: self.makeHeaderFields(),
                                     interceptor: requestInterceptor ?? self.requestInterceptor,
                                     requestModifier: self.requestModifier)
                .logRequest()
                .validate(statusCode: validStatusCodes)
                .publishDecodable(type: R.self)
                .tryMap { result -> R? in
                    try self.validateOptionalResult(result)
                }
                .mapError { $0 as? CoreNetworkError ?? CoreNetworkError.network(error: $0) }
                .eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }
    
    /// Returns publisher for provided API path with optional result.
    ///
    /// - Parameters:
    ///   - path:               `String` that specifies API path.
    ///   - method:             `HTTPMethod` for the request.
    ///   - parameters:         Url parameters.
    ///   - multipartFormData:  Multipart form parameters.
    ///   - requestInterceptor: `RequestInterceptor` to use for the request
    ///   - validStatusCodes:   `Range` of the status codes when response is treated as a success.
    ///
    /// - Returns:    The `AnyPublisher<R?, CoreNetworkError>`.
    public func publisherForPath<R: Decodable>(_ path: String,
                                               method: HTTPMethod = .get,
                                               parameters: [String: Any]? = nil,
                                               multipartFormData: @escaping (MultipartFormData) -> Void,
                                               requestInterceptor: RequestInterceptor? = nil,
                                               validStatusCodes: Range<Int> = 200..<300) -> AnyPublisher<R, CoreNetworkError> {
        let url = generateURLFrom(path: path, parameters: parameters)
        return Just(())
            .setFailureType(to: CoreNetworkError.self)
            .flatMap {
                self.session.upload(multipartFormData: multipartFormData,
                                    to: url,
                                    method: method,
                                    headers: self.makeHeaderFields(),
                                    interceptor: requestInterceptor ?? self.requestInterceptor,
                                    requestModifier: self.requestModifier)
                .logRequest()
                .validate(statusCode: validStatusCodes)
                .publishDecodable(type: R.self)
                .tryMap { result -> R in
                    try self.validateResult(result)
                }
                .mapError { $0 as? CoreNetworkError ?? CoreNetworkError.network(error: $0) }
                .eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private functions
    
    internal func generateURLFrom(path: String, parameters: [String: Any]?) -> URL {
        guard var endPoint = URL(string: self.endPoint) else {
            fatalError("Failed to create reqeust url for endpoint: '\(self.endPoint)'.")
        }
        
        endPoint.appendPathComponent(path)
        
        guard var components = URLComponents(url: endPoint, resolvingAgainstBaseURL: false) else {
            fatalError("Failed to create URL compoenents from url: '\(endPoint)'.")
        }
        
        var requersParameters = parameters ?? [:]
        requersParameters.merge(self.queryItems) { current, _ in return current }
        requersParameters.merge(Settings.globalQueryItems) { current, _ in return current }
         
        components.queryItems = makeQueryItems(from: requersParameters)
        
        guard let url = components.url else {
            fatalError("Failed to create reqeust url from endpoint: '\(endPoint)', path: '\(path)', parameters: '\(parameters ?? [:])'.")
        }
        
        return url
    }
    
    internal func makeQueryItems(from parameters: [String: Any]?) -> [URLQueryItem]? {
        
        guard let parameters = parameters else { return nil }
        guard !parameters.isEmpty else { return nil }
        
        var queryItems: [URLQueryItem] = []
        parameters.forEach { key, value in
            if let arrayOfValues = value as? [Any] {
                let convertedValue = String(arrayOfValues.map { "\($0)" }.joined(separator: ","))
                queryItems.append(URLQueryItem(name: key, value: convertedValue))
            } else {
                queryItems.append(URLQueryItem(name: key, value: "\(value)"))
            }
        }
        return queryItems
    }
    
    private func validateResult<T: Decodable>(_ result: AFDataResponse<T>) throws -> T {
        let value = try validateOptionalResult(result)
        
        guard let value = value else {
            throw CoreNetworkError.noResponse
        }
        
        return value
    }
    
    private func validateOptionalResult<T: Decodable>(_ result: AFDataResponse<T>) throws -> T? {
        self.logResponse(result, file: #file, line: #line, column: #column, funcName: #function)
        
        if let error = result.error {
            switch (error, result.data) {
                case (.responseValidationFailed(reason: .unacceptableStatusCode(let code)), let data?):
                    throw mapError(statusCode: code, errorData: data)
                case (.responseSerializationFailed(reason: .invalidEmptyResponse), _):
                    ()
                default:
                    throw CoreNetworkError.network(error: error)
            }
        }
        
        return result.value
    }
    
    private func mapError(statusCode code: Int, errorData data: Data) -> CoreNetworkError {
        var error: Error? = nil
        if let errorMapper = errorMapper {
            error = errorMapper.map(decoder: self.decoder, statusCode: code, data: data)
        }
        
        return CoreNetworkError.backend(code: code, error: error)
    }
    
    private func logResponse<T: Decodable>(_ response: AFDataResponse<T>,
                                           file: String,
                                           line: Int,
                                           column: Int,
                                           funcName: String) {
        if Log.Level.verbose.isEnabled() {
            let status = response.response?.statusCode ?? 0
            let url = response.request?.url?.absoluteString ?? "???"
            let method = response.request?.httpMethod ?? "???"
            
            let size: String
            let body: String?
            if let data = response.data {
                let bcf = ByteCountFormatter()
                bcf.countStyle = .binary
                size = bcf.string(fromByteCount: Int64(data.count))
                body = String(data: data, encoding: .utf8)
            } else {
                size = "???"
                body = "(empty)"
            }
            
            Log.verbose("Response \(method) \(url) (\(status)) \(size)\n \(body ?? "(invalid encoding)")",
                        file: file,
                        line: line,
                        column: column,
                        funcName: funcName)
        }
        
        if Log.Level.debug.isEnabled() {
            if let metrics = response.metrics {
                let stats = SessionMetrics(source: metrics)
                let renderer = ConsoleRenderer()
                let renderedMetrics = renderer.render(with: stats, taskID: String(response.request.hashValue))
                Log.debug("Response metrics:\n\(renderedMetrics)", file: file, line: line, column: column, funcName: funcName)
            }
        }
    }
    
    internal func makeHeaderFields() -> HTTPHeaders {
        var headers = self.headerFields
        headers.merge(Settings.globalHeaderFields) { current, _ in return current }
        return HTTPHeaders(headers)
    }
}

extension DataRequest {
    
    func logRequest() -> DataRequest {
        guard Log.Level.verbose.isEnabled() else { return self }
        self.cURLDescription { curl in
            let method = self.request?.httpMethod ?? "???"
            let url = self.request?.url?.absoluteString ?? "???"
            let curl = self.cURLDescription()
            Log.verbose("Request \(method) \(url)\n \(curl)")
        }
        
        return self
    }
}
