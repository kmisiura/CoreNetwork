import AnyCodable
import Combine
import Foundation

public enum CoreNetworkError: Error {
    case network(error: Error)
    case noResponse
    case backend(code: Int, error: Error?)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher {
    public func mapErrorToCoreNetworkError() -> Publishers.MapError<Self, CoreNetworkError> {
        return self.mapError { error in
            if let CNError = error as? CoreNetworkError {
                return CNError
            } else {
                return CoreNetworkError.network(error: error)
            }
        }
    }
}
