import XCTest
import Alamofire
import Mocker
@testable import CoreNetwork

final class NetworkTests: XCTestCase {
    
    override func tearDown() {
        Settings.globalQueryItems = [:]
        Settings.globalHeaderFields = [:]
        super.tearDown()
    }
    
    let responseGETItem = CoreNetworkTests.MockResposeModel(id: "responseGETItem", name: nil, age: 1)
        
    func testGetItemRequest() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://testGetItemRequest.efukt.lt",
                                           session: sessions,
                                           requestModifier: nil,
                                           requestInterceptor: nil,
                                           headers: ["TestHeader": "1"])
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        
        let requestURL = URL(string: "https://testGetItemRequest.efukt.lt/unitTest?paramOne=one,two")!
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
            XCTAssertEqual(request.allHTTPHeaderFields?["TestHeader"], "1")
            XCTAssertEqual(request.method, HTTPMethod.get)
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        let cancelable = network.getItem("unitTest", parameters: ["paramOne": ["one", "two"]])
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
    
    func testGetItemsRequest() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://testGetItemsRequest.efukt.lt",
                                                      session: sessions,
                                                      requestModifier: nil,
                                                      requestInterceptor: nil,
                                                      headers: ["TestHeader": "2"])
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        
        let requestURL = URL(string: "https://testGetItemsRequest.efukt.lt/unitTest?paramOne=one")!
        let expectedResponse = [responseGETItem, responseGETItem]
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: false,
                        dataType: .json,
                        statusCode: 200,
                        data: [.get: try! expectedResponse.asData()])
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.url, requestURL)
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], nil)
            XCTAssertEqual(request.allHTTPHeaderFields?["TestHeader"], "2")
            XCTAssertEqual(request.method, HTTPMethod.get)
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        let cancelable = network.getItems("unitTest", parameters: ["paramOne": "one"])
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
    
    func testPostItemRequest() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://testPostItemRequest.efukt.lt",
                                                      session: sessions,
                                                      requestModifier: nil,
                                                      requestInterceptor: nil,
                                                      headers: ["TestHeader": "2"])
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        
        let requestURL = URL(string: "https://testPostItemRequest.efukt.lt/unitTest?paramOne=one")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: false,
                        dataType: .json,
                        statusCode: 200,
                        data: [.post: try! expectedResponse.asData()])
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.url, requestURL)
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], ["requestParam1": "value1"])
            XCTAssertEqual(request.allHTTPHeaderFields?["TestHeader"], "2")
            XCTAssertEqual(request.method, HTTPMethod.post)
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        let cancelable = network.postItem("unitTest", parameters: ["paramOne": "one"], item: ["requestParam1": "value1"])
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
    
    func testPutItemRequest() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://testPutItemRequest.efukt.lt",
                                                      session: sessions,
                                                      requestModifier: nil,
                                                      requestInterceptor: nil,
                                                      headers: ["TestHeader": "2"])
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        
        let requestURL = URL(string: "https://testPutItemRequest.efukt.lt/unitTest?paramOne=one")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: false,
                        dataType: .json,
                        statusCode: 200,
                        data: [.put: try! expectedResponse.asData()])
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.url, requestURL)
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], ["requestParam1": "value1"])
            XCTAssertEqual(request.allHTTPHeaderFields?["TestHeader"], "2")
            XCTAssertEqual(request.method, HTTPMethod.put)
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        let cancelable = network.putItem("unitTest", parameters: ["paramOne": "one"], item: ["requestParam1": "value1"])
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
    
    func testDeleteItemRequest() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://testDeleteItemRequest.efukt.lt",
                                                      session: sessions,
                                                      requestModifier: nil,
                                                      requestInterceptor: nil,
                                                      headers: ["TestHeader": "2"])
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        
        let requestURL = URL(string: "https://testDeleteItemRequest.efukt.lt/unitTest?paramOne=one")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: false,
                        dataType: .json,
                        statusCode: 200,
                        data: [.delete: try! expectedResponse.asData()])
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.url, requestURL)
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], ["requestParam1": "value1"])
            XCTAssertEqual(request.allHTTPHeaderFields?["TestHeader"], "2")
            XCTAssertEqual(request.method, HTTPMethod.delete)
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        let cancelable = network.deleteItem("unitTest", parameters: ["paramOne": "one"], item: ["requestParam1": "value1"])
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
    
    func testStatusCode() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://testStatusCode.efukt.lt",
                                                      session: sessions,
                                                      requestModifier: nil,
                                                      requestInterceptor: nil,
                                                      headers: ["TestHeader": "1"])
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        
        let requestURL = URL(string: "https://testStatusCode.efukt.lt/unitTest?paramOne=one")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: false,
                        dataType: .json,
                        statusCode: 501,
                        data: [.get: try! expectedResponse.asData()])
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.url, requestURL)
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], nil)
            XCTAssertEqual(request.allHTTPHeaderFields?["TestHeader"], "1")
            XCTAssertEqual(request.method, HTTPMethod.get)
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        let cancelable = network.getItem("unitTest", parameters: ["paramOne": "one"])
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .failure(let error):
                        if case let CoreNetworkError.backend(code, _) = error {
                            XCTAssertEqual(code, 501)
                        } else {
                            XCTAssert(false)
                        }
                    case .finished:
                        XCTAssert(false)
                }
                finishExpectation.fulfill()
            }, receiveValue: { response in
                XCTAssertNotNil(response)
                XCTAssertEqual(response, expectedResponse)
            })
        XCTAssertNotNil(cancelable)
        wait(for: [finishExpectation, onRequestExpectation, endpointIsCalledExpectation], timeout: 1.0)
    }
    
    func testFailedRequest() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://testFailedRequest.efukt.lt",
                                                      session: sessions,
                                                      requestModifier: nil,
                                                      requestInterceptor: nil,
                                                      headers: ["TestHeader": "1"])
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        
        let requestURL = URL(string: "https://testFailedRequest.efukt.lt/unitTest?paramOne=one")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: false,
                        dataType: .json,
                        statusCode: 400,
                        data: [.get: try! expectedResponse.asData()],
                        requestError: CoreNetworkTests.Error.requestFailError)
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.url, requestURL)
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], nil)
            XCTAssertEqual(request.allHTTPHeaderFields?["TestHeader"], "1")
            XCTAssertEqual(request.method, HTTPMethod.get)
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        let cancelable = network.getItem("unitTest", parameters: ["paramOne": "one"])
            .sink(receiveCompletion: { error in
                switch error {
                    case .failure(let error):
                        switch error {
                            case let CoreNetworkError.network(underlyingError):
                                if case AFError.sessionTaskFailed(error: let underlyingError) = underlyingError {
                                    XCTAssertNotNil(underlyingError)
                                    let nsError = underlyingError as NSError
                                    let expectedError = CoreNetworkTests.Error.requestFailError as NSError
                                    XCTAssertEqual(nsError.code, expectedError.code)
                                    XCTAssertEqual(nsError.domain, expectedError.domain)
                                } else {
                                    XCTAssert(false)
                                }
                            default:
                                XCTAssert(false)
                        }
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
    
    func testGlobalParameters() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://testGlobalParameters.efukt.lt",
                                                                      session: sessions,
                                                                      requestModifier: nil,
                                                                      requestInterceptor: nil,
                                                                      headers: ["TestHeader": "2"])
        
        Settings.globalQueryItems["GLOBAL_TEST_PARAM"] = 1
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        
        let requestURL = URL(string: "https://testGlobalParameters.efukt.lt/unitTest")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: true,
                        dataType: .json,
                        statusCode: 200,
                        data: [.post: try! expectedResponse.asData()])
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], ["requestParam1": "value1"])
            XCTAssertEqual(request.allHTTPHeaderFields?["TestHeader"], "2")
            XCTAssertEqual(request.method, HTTPMethod.post)
            
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            
            XCTAssertNotNil(urlComponents)
            XCTAssertNotNil(urlComponents?.queryItems)
            XCTAssertEqual(urlComponents?.queryItems?.count, 1)
            
            let qItems = urlComponents?.queryItems?.filter { $0.name == "GLOBAL_TEST_PARAM" }
            
            XCTAssertNotNil(qItems)
            XCTAssertEqual(qItems?.count, 1)
            XCTAssertNotNil(qItems?.first?.value)
            XCTAssertEqual(qItems?.first?.value, "1")
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        let cancelable = network.postItem("unitTest", parameters: [:], item: ["requestParam1": "value1"])
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
    
    func testGlobalParametersOverriding() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://testGlobalParametersOverriding.efukt.lt",
                                                                      session: sessions,
                                                                      requestModifier: nil,
                                                                      requestInterceptor: nil,
                                                                      headers: ["TestHeader": "2"])
        
        Settings.globalQueryItems["GLOBAL_TEST_PARAM"] = 1
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        
        let requestURL = URL(string: "https://testGlobalParametersOverriding.efukt.lt/unitTest?paramOne=one")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: true,
                        dataType: .json,
                        statusCode: 200,
                        data: [.post: try! expectedResponse.asData()])
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], ["requestParam1": "value1"])
            XCTAssertEqual(request.allHTTPHeaderFields?["TestHeader"], "2")
            XCTAssertEqual(request.method, HTTPMethod.post)
            
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            
            XCTAssertNotNil(urlComponents)
            XCTAssertNotNil(urlComponents?.queryItems)
            XCTAssertEqual(urlComponents?.queryItems?.count, 2)
            
            let qItems = urlComponents?.queryItems?.filter { $0.name == "GLOBAL_TEST_PARAM" }
            
            XCTAssertNotNil(qItems)
            XCTAssertEqual(qItems?.count, 1)
            XCTAssertNotNil(qItems?.first?.value)
            XCTAssertEqual(qItems?.first?.value, "2")
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        let cancelable = network.postItem("unitTest", parameters: ["paramOne": "one", "GLOBAL_TEST_PARAM": 2], item: ["requestParam1": "value1"])
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
    
    func testParametersOverriding() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        
        
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://testParametersOverriding.efukt.lt",
                                                                      session: sessions,
                                                                      requestModifier: nil,
                                                                      requestInterceptor: nil)
        
        network.queryItems["REQUEST"] = 2
        network.queryItems["LOCAL_OVERRIDE"] = 2
        network.queryItems["GLOBAL_OVERRIDE"] = 2
        Settings.globalQueryItems["REQUEST"] = 3
        Settings.globalQueryItems["LOCAL_OVERRIDE"] = 3
        Settings.globalQueryItems["GLOBAL_OVERRIDE"] = 3
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        
        let requestURL = URL(string: "https://testParametersOverriding.efukt.lt/unitTest?REQUEST=1&LOCAL_OVERRIDE=1&GLOBAL_OVERRIDE=1")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: true,
                        dataType: .json,
                        statusCode: 200,
                        data: [.post: try! expectedResponse.asData()])
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], ["requestParam1": "value1"])
            XCTAssertEqual(request.method, HTTPMethod.post)
            
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            
            XCTAssertNotNil(urlComponents)
            XCTAssertNotNil(urlComponents?.queryItems)
            XCTAssertEqual(urlComponents?.queryItems?.count, 3)
            
            for item in urlComponents?.queryItems ?? [] {
                XCTAssertEqual(item.value, "1")
            }
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        let parameters = ["REQUEST": 1,
                          "LOCAL_OVERRIDE": 1,
                          "GLOBAL_OVERRIDE": 1]
        
        let cancelable = network.postItem("unitTest", parameters: parameters, item: ["requestParam1": "value1"])
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
    
    func testHeadersOverriding() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        
        
        let network = Network<CoreNetworkTests.MockResposeModel>.init(endPoint: "https://testHeadersOverriding.efukt.lt",
                                                                      session: sessions,
                                                                      requestModifier: nil,
                                                                      requestInterceptor: nil)
        
        network.headerFields["LOCAL_OVERRIDE"] = "2"
        network.headerFields["GLOBAL_OVERRIDE"] = "2"
        Settings.globalHeaderFields["LOCAL_OVERRIDE"] = "3"
        Settings.globalHeaderFields["GLOBAL_OVERRIDE"] = "3"
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        
        let requestURL = URL(string: "https://testHeadersOverriding.efukt.lt/unitTest")!
        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: true,
                        dataType: .json,
                        statusCode: 200,
                        data: [.post: try! expectedResponse.asData()])
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], ["requestParam1": "value1"])
            XCTAssertEqual(request.method, HTTPMethod.post)
            
            let local = request.allHTTPHeaderFields?.first(where: { $0.key == "LOCAL_OVERRIDE" })
            let global = request.allHTTPHeaderFields?.first(where: { $0.key == "GLOBAL_OVERRIDE" })
            
            XCTAssertNotNil(local)
            XCTAssertNotNil(global)
            
            XCTAssertEqual(local?.value, "2")
            XCTAssertEqual(global?.value, "2")
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        let cancelable = network.postItem("unitTest", parameters: [:], item: ["requestParam1": "value1"])
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
    
    func testEmptyResponse() {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let sessions = Session(configuration: configuration)
        
        let network = Network<NoReply>.init(endPoint: "https://testEmptyResponse.efukt.lt",
                                            session: sessions,
                                            requestModifier: nil,
                                            requestInterceptor: nil)
        
        let finishExpectation = expectation(description: "Waiting for finish")
        let onRequestExpectation = expectation(description: "Waiting for request")
        let endpointIsCalledExpectation = expectation(description: "Waiting for endpoint to call")
        
        let requestURL = URL(string: "https://testEmptyResponse.efukt.lt/unitTest?paramOne=one")!
//        let expectedResponse = responseGETItem
        
        var mock = Mock(url: requestURL,
                        ignoreQuery: false,
                        dataType: .json,
                        statusCode: 204,
                        data: [.post: Data()])
        
        mock.onRequest = { request, postBodyArguments in
            
            XCTAssertEqual(request.url, requestURL)
            XCTAssertEqual(request.httpBody, nil)
            XCTAssertEqual(postBodyArguments as? [String: String], ["requestParam1": "value1"])
            XCTAssertEqual(request.method, HTTPMethod.post)
            
            onRequestExpectation.fulfill()
        }
        mock.completion = {
            endpointIsCalledExpectation.fulfill()
        }
        mock.register()
        
        let cancelable = network.postItem("unitTest", parameters: ["paramOne": "one"], item: ["requestParam1": "value1"])
            .sink(receiveCompletion: { error in
                switch error {
                    case .failure(let error):
                        print("Finish with error: \(error)")
                        XCTAssertNil(error)
                    case .finished:
                        XCTAssert(true)
                }
                finishExpectation.fulfill()
            }, receiveValue: { response in
                XCTAssertNil(response)
            })
        XCTAssertNotNil(cancelable)
        wait(for: [finishExpectation, onRequestExpectation, endpointIsCalledExpectation], timeout: 1.0)
    }
    
    
    static var allTests = [
        ("testGetItemRequest", testGetItemRequest),
        ("testGetItemsRequest", testGetItemsRequest),
        ("testPostItemRequest", testPostItemRequest),
        ("testPutItemRequest", testPutItemRequest),
        ("testDeleteItemRequest", testDeleteItemRequest),
        ("testStatusCode", testStatusCode),
        ("testFailedRequest", testFailedRequest),
        ("testGlobalParameters", testGlobalParameters),
        ("testGlobalParametersOverriding", testGlobalParametersOverriding),
        ("testParametersOverriding", testParametersOverriding),
        ("testHeadersOverriding", testHeadersOverriding),
        ("testEmptyResponse", testEmptyResponse),
    ]
}
