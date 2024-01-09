import Foundation

public extension HTTPURLResponse {
    func validate(statusCode acceptableStatusCodes: Range<Int>) throws {
        guard acceptableStatusCodes.contains(self.statusCode) else {
            throw CoreNetworkError.backend(code: statusCode, error: nil)
        }
    }
}
