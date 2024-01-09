import Alamofire
@testable import CoreNetwork
import Mocker
import XCTest

final class JWTInjectorTests: XCTestCase {
    
    let responseGETItem = CoreNetworkTests.MockResposeModel(id: "responseTestInject", name: nil, age: 0)
    
    enum JWTInjectorTestError: Error {
        case error
    }
    
    func testInject() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        let jwInjector = JWTInjector(headerFieldKey: "FIREBASE_JWT")
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://test.efukt.lt",
                                                                      session: sessions,
                                                                      requestModifier: nil,
                                                                      requestInterceptor: jwInjector,
                                                                      headers: nil)
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        
        let requestURL = URL(string: "https://test.efukt.lt/testInject")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: false,
                        dataType: .json,
                        statusCode: 200,
                        data: [.get: try! expectedResponse.asData()])
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.url, requestURL)
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], nil)
            XCTAssertEqual(request.allHTTPHeaderFields?["FIREBASE_JWT"], "TEST_JWT_TOKEN")
            XCTAssertEqual(request.method, HTTPMethod.get)
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        jwInjector.authorizationToken = "TEST_JWT_TOKEN"
        
        let cancelable = network.getItem("testInject", parameters: nil)
            .sink(receiveCompletion: { error in
                switch error {
                    case .failure(let error):
                        XCTAssertNil(error)
                    case .finished:
                        XCTAssert(true)
                }
                finishExpectation.fulfill()
            }, receiveValue: { response in
                XCTAssertNotNil(response)
                XCTAssertEqual(response, expectedResponse)
            })
        XCTAssertNotNil(cancelable)
        wait(for: [finishExpectation, onRequestExpectation, endpointIsCalledExpectation], timeout: 1.0)
    }
    
    func testRetry() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        let jwInjector = JWTInjector(headerFieldKey: "FIREBASE_JWT")
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://test.efukt.lt",
                                                                      session: sessions,
                                                                      requestModifier: nil,
                                                                      requestInterceptor: jwInjector,
                                                                      headers: nil)
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        let authorization401HandlerExpectation = expectation(description: "Waiting to call authorization401Handler")
        
        onRequestExpectation.expectedFulfillmentCount = 1
        endpointIsCalledExpectation.expectedFulfillmentCount = 1
        authorization401HandlerExpectation.expectedFulfillmentCount = 2
        
        let requestURL = URL(string: "https://test.efukt.lt/testRetry")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: false,
                        dataType: .json,
                        statusCode: 401,
                        data: [.get: try! expectedResponse.asData()],
                        requestError: nil)
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.url, requestURL)
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], nil)
            XCTAssertEqual(request.allHTTPHeaderFields?["FIREBASE_JWT"], "TEST_JWT_TOKEN")
            XCTAssertEqual(request.method, HTTPMethod.get)
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        jwInjector.authorizationToken = "TEST_JWT_TOKEN"
        jwInjector.authorization401Handler = {
            authorization401HandlerExpectation.fulfill()
            return nil
        }
        
        let cancelable = network.getItem("testRetry", parameters: nil)
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .failure(let error):
                        XCTAssertNotNil(error)
                    case .finished:
                        XCTAssert(false)
                }
                finishExpectation.fulfill()
            }, receiveValue: { response in
                XCTAssertNotNil(response)
                XCTAssertEqual(response, expectedResponse)
            })
        XCTAssertNotNil(cancelable)
        wait(for: [finishExpectation, onRequestExpectation, endpointIsCalledExpectation, authorization401HandlerExpectation], timeout: 1)
    }
    
    func testRecover() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        let jwInjector = JWTInjector(headerFieldKey: "FIREBASE_JWT")
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://test.efukt.lt",
                                                                      session: sessions,
                                                                      requestModifier: nil,
                                                                      requestInterceptor: jwInjector,
                                                                      headers: nil)
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        let authorization401HandlerExpectation = expectation(description: "Waiting to call authorization401Handler")
        
        onRequestExpectation.expectedFulfillmentCount = 3
        endpointIsCalledExpectation.expectedFulfillmentCount = 3
        authorization401HandlerExpectation.expectedFulfillmentCount = 2
        
        let requestURL = URL(string: "https://test.efukt.lt/testRecover")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: false,
                        dataType: .json,
                        statusCode: 401,
                        data: [.get: try! expectedResponse.asData()],
                        requestError: nil)
        
        var requestCount = 0
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.url, requestURL)
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], nil)
            XCTAssertEqual(request.method, HTTPMethod.get)
            if requestCount == 0 {
                XCTAssertEqual(request.allHTTPHeaderFields?["FIREBASE_JWT"], "TEST_JWT_TOKEN")
            } else {
                XCTAssertEqual(request.allHTTPHeaderFields?["FIREBASE_JWT"], "NEW_JWT_TOKEN")
            }
            requestCount += 1
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        jwInjector.authorizationToken = "TEST_JWT_TOKEN"
        jwInjector.authorization401Handler = {
            authorization401HandlerExpectation.fulfill()
            return "NEW_JWT_TOKEN"
        }
        
        let cancelable = network.getItem("testRecover", parameters: nil)
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .failure(let error):
                        XCTAssertNotNil(error)
                    case .finished:
                        XCTAssert(false)
                }
                finishExpectation.fulfill()
            }, receiveValue: { response in
                XCTAssertNotNil(response)
                XCTAssertEqual(response, expectedResponse)
            })
        XCTAssertNotNil(cancelable)
        wait(for: [finishExpectation, onRequestExpectation, endpointIsCalledExpectation, authorization401HandlerExpectation], timeout: 3)
    }
    
    func testNot401Recover() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        let jwInjector = JWTInjector(headerFieldKey: "FIREBASE_JWT")
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://test.efukt.lt",
                                                                      session: sessions,
                                                                      requestModifier: nil,
                                                                      requestInterceptor: jwInjector,
                                                                      headers: nil)
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        let authorization401HandlerExpectation = expectation(description: "Waiting to call authorization401Handler")
        
        onRequestExpectation.expectedFulfillmentCount = 1
        endpointIsCalledExpectation.expectedFulfillmentCount = 1
        authorization401HandlerExpectation.isInverted = true
        
        let requestURL = URL(string: "https://test.efukt.lt/testRetry")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: false,
                        dataType: .json,
                        statusCode: 409,
                        data: [.get: try! expectedResponse.asData()],
                        requestError: nil)
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.url, requestURL)
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], nil)
            XCTAssertEqual(request.allHTTPHeaderFields?["FIREBASE_JWT"], "TEST_JWT_TOKEN")
            XCTAssertEqual(request.method, HTTPMethod.get)
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        jwInjector.authorizationToken = "TEST_JWT_TOKEN"
        jwInjector.authorization401Handler = {
            authorization401HandlerExpectation.fulfill()
            return nil
        }
        
        let cancelable = network.getItem("testRetry", parameters: nil)
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .failure(let error):
                        XCTAssertNotNil(error)
                    case .finished:
                        XCTAssert(true)
                }
                finishExpectation.fulfill()
            }, receiveValue: { response in
                XCTAssertNotNil(response)
                XCTAssertEqual(response, expectedResponse)
            })
        XCTAssertNotNil(cancelable)
        wait(for: [finishExpectation, onRequestExpectation, endpointIsCalledExpectation, authorization401HandlerExpectation], timeout: 1)
    }
    
    func testNoTokenRecover() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        let jwInjector = JWTInjector(headerFieldKey: "FIREBASE_JWT")
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://test.efukt.lt",
                                                                      session: sessions,
                                                                      requestModifier: nil,
                                                                      requestInterceptor: jwInjector,
                                                                      headers: nil)
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        let authorization401HandlerExpectation = expectation(description: "Waiting to call authorization401Handler")
        
        onRequestExpectation.expectedFulfillmentCount = 1
        endpointIsCalledExpectation.expectedFulfillmentCount = 1
        authorization401HandlerExpectation.expectedFulfillmentCount = 1
        
        let requestURL = URL(string: "https://test.efukt.lt/testNoTokenRecover")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: false,
                        dataType: .json,
                        statusCode: 200,
                        data: [.get: try! expectedResponse.asData()],
                        requestError: nil)
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.url, requestURL)
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], nil)
            XCTAssertEqual(request.method, HTTPMethod.get)
            XCTAssertEqual(request.allHTTPHeaderFields?["FIREBASE_JWT"], "NEW_JWT_TOKEN")
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        jwInjector.authorization401Handler = {
            authorization401HandlerExpectation.fulfill()
            return "NEW_JWT_TOKEN"
        }
        
        let cancelable = network.getItem("testNoTokenRecover", parameters: nil)
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .failure(let error):
                        XCTAssertNil(error)
                    case .finished:
                        XCTAssert(true)
                }
                finishExpectation.fulfill()
            }, receiveValue: { response in
                XCTAssertNotNil(response)
                XCTAssertEqual(response, expectedResponse)
            })
        XCTAssertNotNil(cancelable)
        wait(for: [finishExpectation, onRequestExpectation, endpointIsCalledExpectation, authorization401HandlerExpectation], timeout: 3)
    }
}
