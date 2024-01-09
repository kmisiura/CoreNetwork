import Combine
import Foundation

protocol SingularStore {
    
    associatedtype Value
    
    /**
     * Stores single value to store.
     * @param value Single value to store.
     * @return Promise
     */
    func store(value: Value) -> Future<Value, Error>
    
    /**
     * Returns an singular value for key.
     * @param key Key of object to retreive.
     * @return Promise of singular value.
     */
    func get() -> Future<Value?, Error>
    
    /**
     * Clears all values in store.
     * @return Promise
     */
    func clear() -> Future<Void, Error>
}
