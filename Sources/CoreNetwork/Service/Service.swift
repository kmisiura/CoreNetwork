public protocol Service {
    associatedtype DataType: Decodable
    var network: Network<DataType> { get }
}
