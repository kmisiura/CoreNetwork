import XCTest
@testable import CoreNetwork

final class CoreNetworkTests: XCTestCase {
    
    enum Error: Swift.Error {
        case requestFailError
    }
    
    struct MockResposeModel: Codable, Hashable {
        let id: String
        let name: String?
        let age: Int?
    }
}
