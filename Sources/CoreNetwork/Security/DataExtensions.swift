import Foundation

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let hexDigits = Array((options.contains(.upperCase) ? "0123456789ABCDEF" : "0123456789abcdef").utf16)
        var chars: [unichar] = []
        chars.reserveCapacity(2 * count)
        for byte in self {
            chars.append(hexDigits[Int(byte / 16)])
            chars.append(hexDigits[Int(byte % 16)])
        }
        return String(utf16CodeUnits: chars, count: chars.count)
    }
}

extension String {
    var bytesArray: [UInt8] {
        var byteArray = [UInt8]()
        byteArray += self.utf8
        return byteArray
    }
}

extension Array where Element == UInt8 {
    var hexString: String {
        var hexBits = "" as String
        for value in self {
            hexBits += NSString(format: "%2x", value) as String
        }
        
        // Replace space from single digit hex transform
        return hexBits.replacingOccurrences(of: " ", with: "0", options: NSString.CompareOptions.caseInsensitive)
    }
}
