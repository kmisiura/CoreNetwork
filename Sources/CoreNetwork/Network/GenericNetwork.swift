import Alamofire
import Combine
import Foundation
import OSLogger

public protocol MetricsCollector {
    func requestDidStart(id: UUID, requestURL: String, method: HTTPMethod, parameters: Parameters?)
    func requestDidFinish(id: UUID, requestURL: String, method: HTTPMethod, parameters: Parameters?, statusCode: Int?, error: Error?)
}

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
    private let requestInterceptor: RequestInterceptor?
    private let errorMapper: NetworkErrorMapper?
    private let cacheURL: URL?
    
    public let name: String
    
    public let session: Session
    
    public var metricsCollector: MetricsCollector?
    
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
    
    public init(endPoint: String,
                decoder: JSONDecoder = JSONDecoder(),
                encoding: ParameterEncoding = JSONEncoding.default,
                session: Session? = nil,
                enableCaching: Bool? = nil,
                requestInterceptor: RequestInterceptor? = nil,
                headers: [String: String]? = nil,
                errorMapper: NetworkErrorMapper? = nil,
                name: String? = nil) {
        self.endPoint = endPoint
        self.decoder = decoder
        self.encoding = encoding
        self.requestInterceptor = requestInterceptor
        self.errorMapper = errorMapper
        self.headerFields = headers ?? [:]
        let networkName = name ?? "Generic \(endPoint)"
        self.name = networkName
        
        if let session = session {
            self.session = session
            self.cacheURL = nil
            return
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        
        if enableCaching == true {
            if let cacheURL = GenericNetwork.cacheURL(name: networkName) {
                configuration.urlCache = GenericNetwork.newCache(cacheURL: cacheURL)
                configuration.requestCachePolicy = .returnCacheDataElseLoad
                self.cacheURL = cacheURL
            } else {
                Log.error("Failed to create cache URL")
                configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
                self.cacheURL = nil
            }
        } else {
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.cacheURL = nil
        }
        
        self.session = Session(configuration: configuration)
    }
    
    private static func cacheURL(name: String) -> URL? {
        let cacheURLKey = "\(name).cache"
        if let url = UserDefaults.standard.url(forKey: cacheURLKey) {
            Log.debug("\(name), there's old cache URL saved.")
            return url
        } else if let url = GenericNetwork.createCacheDirectory(name: name) {
            Log.debug("\(name), no old cache, creating new one.")
            UserDefaults.standard.set(url, forKey: cacheURLKey)
            return url
        } else {
            Log.error("Failed to create cache URL")
            return nil
        }
    }
    
    private static func createCacheDirectory(name: String) -> URL? {
        guard var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        url.appendPathComponent(name, isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: url,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
            url.appendPathComponent("urlcache", isDirectory: false)
            return url
        } catch  {
            Log.error(error)
            return nil
        }
    }
    
    private static func newCache(cacheURL: URL) -> URLCache {
        let cache = URLCache(memoryCapacity: 2 * 1024 * 1024,
                             diskCapacity: 100 * 1024 * 1024,
                             directory: cacheURL)
        return cache
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
        let requestId = UUID()
        return Just(())
            .setFailureType(to: CoreNetworkError.self)
            .flatMap {
                self.logMetricStart(url.absoluteString, method: method, parameters: parameters, requestId: requestId)
                return self.session.request(url,
                                            method: method,
                                            encoding: self.encoding,
                                            headers: self.makeHeaderFields(),
                                            interceptor: requestInterceptor ?? self.requestInterceptor)
                .logRequest(requestId: requestId)
                .validate(statusCode: validStatusCodes)
                .publishDecodable(type: R.self, decoder: self.decoder)
                .tryMap { result -> R in try self.validateResult(result, requestId: requestId) }
                .mapErrorToCoreNetworkError()
                .eraseToAnyPublisher()
            }
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
        let requestId = UUID()
        return Just(())
            .setFailureType(to: CoreNetworkError.self)
            .flatMap {
                self.logMetricStart(url.absoluteString, method: method, parameters: parameters, requestId: requestId)
                return self.session.request(url,
                                     method: method,
                                     parameters: item,
                                     encoding: self.encoding,
                                     headers: self.makeHeaderFields(),
                                     interceptor: requestInterceptor ?? self.requestInterceptor)
                .logRequest(requestId: requestId)
                .validate(statusCode: validStatusCodes)
                .publishDecodable(type: R.self, decoder: self.decoder)
                .tryMap { result -> R in
                    try self.validateResult(result, requestId: requestId)
                }
                .mapErrorToCoreNetworkError()
                .eraseToAnyPublisher()
            }
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
        let requestId = UUID()
        return Just(())
            .setFailureType(to: CoreNetworkError.self)
            .flatMap {
                self.logMetricStart(url.absoluteString, method: method, parameters: parameters, requestId: requestId)
                return self.session.request(url,
                                            method: method,
                                            parameters: item,
                                            encoding: self.encoding,
                                            headers: self.makeHeaderFields(),
                                            interceptor: requestInterceptor ?? self.requestInterceptor)
                .logRequest(requestId: requestId)
                .validate(statusCode: validStatusCodes)
                .publishDecodable(type: R.self, decoder: self.decoder)
                .tryMap { result -> R? in
                    try self.validateOptionalResult(result, requestId: requestId)
                }
                .mapErrorToCoreNetworkError()
                .eraseToAnyPublisher()
            }
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
        let requestId = UUID()
        return Just(())
            .setFailureType(to: CoreNetworkError.self)
            .flatMap {
                self.logMetricStart(url.absoluteString, method: method, parameters: parameters, requestId: requestId)
                return self.session.upload(multipartFormData: multipartFormData,
                                           to: url,
                                           method: method,
                                           headers: self.makeHeaderFields(),
                                           interceptor: requestInterceptor ?? self.requestInterceptor)
                .logRequest(requestId: requestId)
                .validate(statusCode: validStatusCodes)
                .publishDecodable(type: R.self, decoder: self.decoder)
                .tryMap { result -> R in
                    try self.validateResult(result, requestId: requestId)
                }
                .mapErrorToCoreNetworkError()
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    public func removeAllCachedResponses() {
        Log.verbose()
        if let urlCache = self.session.session.configuration.urlCache, let cacheURL = self.cacheURL {
            urlCache.removeAllCachedResponses()
            self.session.session.configuration.urlCache = nil
            do {
                try FileManager.default.removeItem(at: cacheURL)
            } catch {
                Log.error("Error while trying to remove cache at url: '\(cacheURL). Error: \(error)")
            }
            Log.verbose("Cahce removed, creting new one.")
            self.session.session.configuration.urlCache = GenericNetwork.newCache(cacheURL: cacheURL)
        }
    }
    
    // MARK: - Private functions
    
    internal func generateURLFrom(path: String, parameters: [String: Any]?) -> URL {
        
        guard let endPoint = URL(string: self.endPoint) else {
            fatalError("Failed to create reqeust url for endpoint: '\(self.endPoint)'.")
        }
        guard var components = URLComponents(url: endPoint, resolvingAgainstBaseURL: true) else {
            fatalError("Failed to create URL compoenents from url: '\(endPoint)'.")
        }
        
        components.path = path
        if components.scheme == nil {
            components.scheme = "https"
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
    
    private func validateResult<T: Decodable>(_ result: AFDataResponse<T>, requestId: UUID) throws -> T {
        let value = try validateOptionalResult(result, requestId: requestId)
        
        guard let value = value else {
            let url = result.request?.url?.absoluteString ?? "UNKNOWN"
            throw CoreNetworkError.noResponse(request: url)
        }
        
        return value
    }
    
    private func validateOptionalResult<T: Decodable>(_ result: AFDataResponse<T>, requestId: UUID) throws -> T? {
        self.logResponse(result, requestId: requestId, file: #file, line: #line, column: #column, funcName: #function)
        self.logMetricEnd(response: result, requestId: requestId)
        
        if let error = result.error {
            switch (error, result.data) {
                case (.responseValidationFailed(reason: .unacceptableStatusCode(let code)), let data?):
                    let url = result.request?.url?.absoluteString ?? "UNKNOWN"
                    throw mapError(statusCode: code, errorData: data, request: url)
                case (.responseSerializationFailed(reason: .invalidEmptyResponse), _):
                    ()
                default:
                    let url = result.request?.url?.absoluteString ?? "UNKNOWN"
                    throw CoreNetworkError.network(error: error, request: url)
            }
        }
        
        return result.value
    }
    
    private func mapError(statusCode code: Int, errorData data: Data, request url: String) -> CoreNetworkError {
        var error: Error? = nil
        if let errorMapper = errorMapper {
            error = errorMapper.map(decoder: self.decoder, statusCode: code, data: data)
        }
        
        return CoreNetworkError.backend(code: code, error: error, request: url)
    }
    
    private func logResponse<T: Decodable>(_ response: AFDataResponse<T>,
                                           requestId: UUID,
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
                if data.count > 1024*100 {
                    body = "Reponse is too big to print."
                } else {
                    body = String(data: data, encoding: .utf8)
                }
            } else {
                size = "???"
                body = "(empty)"
            }
            
            Log.verbose("Response \(requestId) -> \(method) \(url) (\(status)) \(size)\n \(body ?? "(invalid encoding)")",
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
                Log.debug("Response \(requestId) metrics:\n\(renderedMetrics)", file: file, line: line, column: column, funcName: funcName)
            }
        }
    }
    
    internal func makeHeaderFields() -> HTTPHeaders {
        var headers = self.headerFields
        headers.merge(Settings.globalHeaderFields) { current, _ in return current }
        return HTTPHeaders(headers)
    }
    
    internal func logMetricStart(_ requestURL: String, method: HTTPMethod, parameters: Parameters?, requestId: UUID) {
        self.metricsCollector?.requestDidStart(id: requestId, requestURL: requestURL, method: method, parameters: parameters)
    }
    
    internal func logMetricEnd<T: Decodable>(response: AFDataResponse<T>, requestId: UUID) {
        let url = response.request?.url?.absoluteString ?? "???"
        let method = HTTPMethod(rawValue: response.request?.httpMethod ?? "???")
        let parameters = response.request?.allHTTPHeaderFields ?? [:]
        let statusCode = response.response?.statusCode ?? 0
        let error = response.error
        self.metricsCollector?.requestDidFinish(id: requestId,
                                                requestURL: url,
                                                method: method,
                                                parameters: parameters,
                                                statusCode: statusCode,
                                                error: error)
    }
}

extension DataRequest {
    
    func logRequest(requestId: UUID) -> DataRequest {
        guard Log.Level.verbose.isEnabled() else { return self }
        self.cURLDescription { curl in
            let method = self.request?.httpMethod ?? "???"
            let url = self.request?.url?.absoluteString ?? "???"
            let curl = self.cURLDescription()
            Log.verbose("Request \(requestId) -> \(method) \(url)\n \(curl)")
        }
        
        return self
    }
}
