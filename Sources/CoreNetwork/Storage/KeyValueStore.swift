import Combine
import Foundation

protocol KeyValueStore {
    
    associatedtype Key: Codable, Hashable
    associatedtype Value
    
    /**
     * Stores single value to store.
     * @param value Single value to store.
     * @return Promise
     */
    func store(value: Value, key: Key) -> Future<Value, Error>
    
    /**
     * Returns an singular value for key.
     * @param key Key of object to retreive.
     * @return Promise of singular value.
     */
    func get(key: Key) -> Future<Value?, Error>
    
    /**
     * Returns an collection of all values stored.
     * @return Guarantee of values collection.
     */
    func getAll() -> Future<[Key: Value], Error>
    
    /**
     * Removes value for key
     * @return Promise
     */
    func remove(key: Key) -> Future<Void, Error>
    
    /**
     * Clears all values in store.
     * @return Promise
     */
    func clear() -> Future<Void, Error>
}
