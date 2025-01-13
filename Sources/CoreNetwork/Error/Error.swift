import AnyCodable
import Combine
import Foundation

public enum CoreNetworkError: Error {
    case network(error: Error, request: String)
    case noResponse(request: String)
    case unacceptableStatusCodes(request: String)
    case backend(code: Int, error: Error?, request: String)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher {
    public func mapErrorToCoreNetworkError(requestURL: String? = nil) -> Publishers.MapError<Self, CoreNetworkError> {
        return self.mapError { error in
            if let CNError = error as? CoreNetworkError {
                return CNError
            } else {
                return CoreNetworkError.network(error: error, request: requestURL ?? "UNKNOWN")
            }
        }
    }
}
