import Combine
import Foundation
import OSLogger

public final class UserDefaultsKVStore<T: Codable>: KeyValueStore {
    
    public typealias Key = String
    typealias Value = T
    
    private var storageKey: String
    private var storage: [Key: Value] = [:]
    
    private let operationQueue = DispatchQueue(label: "UserDefaultsKVStore.KeyValueStore.\(Key.self)\(Value.self)", qos: .default)
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
        self.storageKey = "\(T.self)KeyValueStore"
        self.userDefaults.data(forKey: self.storageKey)
        self.readUD()
    }
    
    public func store(value: T, key: String) -> Future<T, Error> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            self.operationQueue.sync {
                self.storage[key] = value
                self.storeUD()
            }
            promise(.success(value))
        }
    }
    
    public func get(key: String) -> Future<T?, Error> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            var value: Value? = nil
            self.operationQueue.sync {
                value = self.storage[key]
            }
            promise(.success(value))
        }
    }
    
    public func getAll() -> Future<[Key : T], Error> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            var value: [Key: T] = [:]
            self.operationQueue.sync {
                value = self.storage
            }
            promise(.success(value))
        }
    }
    
    public func remove(key: String) -> Future<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            self.operationQueue.sync {
                self.storage[key] = nil
                self.storeUD()
            }
            promise(.success(()))
        }
    }
    
    public func clear() -> Future<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            self.operationQueue.sync {
                self.storage = [:]
                self.clearUD()
            }
            promise(.success(()))
        }
    }
    
    private func storeUD() {
        do {
            let encoded = try self.encoder.encode(self.storage)
            self.userDefaults.set(encoded, forKey: self.storageKey)
        } catch {
            Log.error("Failed do encode storage: \(error)")
        }
    }
    
    private func readUD() {
        guard let value = self.userDefaults.object(forKey: self.storageKey) as? Data else { return }
        do {
            let decoded = try self.decoder.decode([Key: Value].self, from: value)
            self.storage = decoded
        } catch {
            Log.error("Failed do decode storage: \(error)")
        }
    }
    
    private func clearUD() {
        self.userDefaults.set(nil, forKey: self.storageKey)
    }
}
