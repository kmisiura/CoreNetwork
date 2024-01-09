import Foundation

public extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try self.asData()
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "JSONSerialization", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize into dictionary \(self)"])
        }
        return dictionary
    }
    
    func asData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
}
