import Foundation

public extension HTTPURLResponse {
    func validate(statusCode acceptableStatusCodes: Range<Int>, request url: String) throws {
        guard acceptableStatusCodes.contains(self.statusCode) else {
            throw CoreNetworkError.unacceptableStatusCodes(request: url)
        }
    }
}
