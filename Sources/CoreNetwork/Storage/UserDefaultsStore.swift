import Combine
import Foundation
import OSLogger

public final class UserDefaultsStore<T: Codable>: SingularStore {
    
    typealias Value = T
    
    private var storageKey: String
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
        self.storageKey = "\(T.self)SingularStore"
    }
    
    public func store(value: T) -> Future<T, Error> {
        return .init { promise in
            do {
                let encoded = try self.encoder.encode(value)
                self.userDefaults.set(encoded, forKey: self.storageKey)
                promise(.success(value))
            } catch {
                Log.error("Failed do encode storage: \(error)")
                promise(.failure(error))
            }
        }
    }
    
    public func get() -> Future<T?, Error> {
        return .init { promise in
            guard let value = self.userDefaults.object(forKey: self.storageKey) as? Data else {
                promise(.success(nil))
                return
            }
            do {
                let decoded = try self.decoder.decode(Value.self, from: value)
                promise(.success(decoded))
            } catch {
                Log.error("Failed do decode storage: \(error)")
                promise(.failure(error))
            }
        }
    }
    
    public func clear() -> Future<Void, Error> {
        return .init { (promise) in
            self.userDefaults.set(nil, forKey: self.storageKey)
            promise(.success(()))
        }
    }
}
