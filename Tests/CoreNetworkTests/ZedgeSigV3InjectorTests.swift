import XCTest
@testable import CoreNetwork

final class SigV3InjectorTests: XCTestCase {
    
    let signature = SigV3(appId: "wallpapers.ios",
                               signingKey: [0xaa, 0xb5, 0x93, 0x8d, 0xad, 0xab, 0x9b, 0xbb, 0x84, 0xa5,
                                            0x8e, 0xa4, 0xa9, 0xbd, 0x99, 0x86, 0xb6, 0xb5, 0xa9, 0xa6,
                                            0xbe, 0x8d, 0xfa, 0x87, 0x8d, 0x9b, 0x9e, 0x81, 0xbd, 0x98,
                                            0xfd, 0x8d, 0xb6, 0x9e, 0x80, 0x86, 0xb9, 0xaf, 0xfa, 0x86,
                                            0xb5, 0xfe, 0xfe, 0x8e, 0xbf, 0x80, 0xad, 0xa3, 0x85, 0x9c,
                                            0x8a, 0x82, 0x88, 0x81, 0x82, 0xff, 0xa5, 0xbe, 0x8f, 0xb9,
                                            0xa5, 0x99, 0xa0, 0x84])

    // Decode
    func testDecode() {
        let decoded = signature.decoded()
        let string = String(bytes: decoded, encoding: .utf8)
        XCTAssertEqual(string, "fy_AagWwHiBheqUJzyejrA6KAWRMqT1AzRLJuc6Jy22BsLaoIPFNDMN3irCuiUlH", "Decoded secret did not match the expected value")
    }

    // ByteArrayToHexString
    func testByteArrayToHexString_zeroPrefix() {
        let byteArray: [UInt8] = [11]
        let actual = byteArray.hexString
        XCTAssertEqual(actual, "0b")
    }

    func testByteArrayToHexString_lowerCase() {
        let byteArray: [UInt8] = [252]
        let actual = byteArray.hexString
        XCTAssertEqual(actual, "fc")
    }

    func testByteArrayToHexString_combination() {
        let byteArray: [UInt8] = [5, 10, 15, 60, 255]
        let actual = byteArray.hexString
        XCTAssertEqual(actual, "050a0f3cff")
    }

    //StringToByteArray
    func testStringToByteArray() {
        let byteArray = "Test".bytesArray
        XCTAssertEqual(byteArray, [84, 101, 115, 116])
    }

    // HmacSha1
    func testHmacSha1() {
        let content = "Text to sign"
        let secret = "Key to sign with"

        let hexSignature = content.digest(.sha1, key: secret)

        XCTAssertEqual(hexSignature, "32c8d1a25a72ee91b4218193c6b72d1db4eeff25")
    }

    func testSignature() {
        let rawPayload = """
        {"events":[{"event":"RESUME_APP","zid":"48917a5fcf0fedeca5b04d2191767cd3f630d85e"}]}
        """
        let data = rawPayload.data(using: .utf8)

        var request = URLRequest(url:
            URL(string: "https://logsink.efukt.lt/api/logsink/v4/events?appid=wallpapers.ios&build=DEBUG")!)
        request.httpMethod = "POST"
        request.httpBody = data

        try! self.signature.adapt(request: &request, time: "1573486236985")

        XCTAssertEqual(request.allHTTPHeaderFields![SigV3.DefaultKeys.signatureHeader],
                       "f52db8fd539bb31b62a3828b1e9d6b11c3aea0d4")
    }

    func testUrl() {
        let rawPayload = """
        {"events":[{"event":"RESUME_APP","zid":"48917a5fcf0fedeca5b04d2191767cd3f630d85e"}]}
        """
        let data = rawPayload.data(using: .utf8)

        var request = URLRequest(url:URL(string: "https://logsink.efukt.lt/api/logsink/v4/events?appid=wallpapers.ios&build=DEBUG")!)
        request.httpMethod = "POST"
        request.httpBody = data

        try! self.signature.adapt(request: &request)

        XCTAssertEqual(request.url?.query, "appid=wallpapers.ios&build=DEBUG")
    }
}
