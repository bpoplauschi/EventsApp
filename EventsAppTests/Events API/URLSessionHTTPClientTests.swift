//
//  URLSessionHTTPClientTests.swift
//  EventsAppTests
//
//  Created by Bogdan on 19.07.2022.
//

import EventsApp
import XCTest

class URLSessionHTTPClient {
    private let session: URLSession
    
    typealias Result = HTTPClient.Result
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    private struct URLSessionTaskWrapper: HTTPClientTask {
        let wrapped: URLSessionTask
        
        func cancel() {
            wrapped.cancel()
        }
    }
    
    init(session: URLSession) {
        self.session = session
    }
    
    @discardableResult
    func get(from url: URL, completion: @escaping (Result) -> Void) -> HTTPClientTask {
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            completion(self.createResult(fromData: data, response: response, error: error))
        }
        task.resume()
        return URLSessionTaskWrapper(wrapped: task)
    }
    
    @discardableResult
    func post(to url: URL, body: Data, completion: @escaping (Result) -> Void) -> HTTPClientTask {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        let task = session.dataTask(with: request) { data, response, error in
            switch (data, response, error) {
            case let (_, _, .some(error)):
                completion(.failure(error))
                
            case let (.some(data), .some(response as HTTPURLResponse), .none):
                completion(.success((data, response)))
                
            default:
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }
        task.resume()
        return URLSessionTaskWrapper(wrapped: task)
    }
    
    private func createResult(fromData data: Data?, response: URLResponse?, error: Error?) -> HTTPClient.Result {
        Result {
            switch (data, response, error) {
            case let (_, _, .some(error)):
                throw error
                
            case let (.some(data), .some(response as HTTPURLResponse), .none):
                return (data, response)
                
            default:
                throw UnexpectedValuesRepresentation()
            }
        }
    }
}

class URLSessionHTTPClientGETTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.removeStub()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        
        URLProtocolStub.observerRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT(testCase: self).get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_cancelGetFromURLTask_cancelsURLRequest() throws {
        let receivedError = try XCTUnwrap(resultErrorForGetFromUrl(taskHandler: { $0.cancel() }) as? NSError)

        XCTAssertEqual(receivedError.code, URLError.cancelled.rawValue)
    }
    
    func test_getFromURL_failsOnRequestError() throws {
        let requestError = anyNSError()
        
        let receivedError = try XCTUnwrap(resultErrorForGetFromUrl(with: (data: nil, response: nil, error: requestError)))
        
        XCTAssertEqual((receivedError as NSError).domain, requestError.domain)
        XCTAssertEqual((receivedError as NSError).code, requestError.code)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentations() {
        XCTAssertNotNil(resultErrorForGetFromUrl(with: (data: nil, response: nil, error: nil)))
        XCTAssertNotNil(resultErrorForGetFromUrl(with: (data: nil, response: nonHTTPURLResponse(), error: nil)))
        XCTAssertNotNil(resultErrorForGetFromUrl(with: (data: anyData(), response: nil, error: nil)))
        XCTAssertNotNil(resultErrorForGetFromUrl(with: (data: anyData(), response: nil, error: anyNSError())))
        XCTAssertNotNil(resultErrorForGetFromUrl(with: (data: nil, response: nonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorForGetFromUrl(with: (data: nil, response: anyHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorForGetFromUrl(with: (data: anyData(), response: nonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorForGetFromUrl(with: (data: anyData(), response: anyHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorForGetFromUrl(with: (data: anyData(), response: nonHTTPURLResponse(), error: nil)))
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() throws {
        let data = anyData()
        let response = anyHTTPURLResponse()
        
        let receivedValues = try XCTUnwrap(resultValuesForGetFromUrl(with: (data: data, response: response, error: nil)))
        
        XCTAssertEqual(receivedValues.data, data)
        XCTAssertEqual(receivedValues.response.url, response.url)
        XCTAssertEqual(receivedValues.response.statusCode, response.statusCode)
    }
    
    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() throws {
        let response = anyHTTPURLResponse()
        
        let receivedValues = try XCTUnwrap(resultValuesForGetFromUrl(with: (data: nil, response: response, error: nil)))
        
        let emptyData = Data()
        XCTAssertEqual(receivedValues.data, emptyData)
        XCTAssertEqual(receivedValues.response.url, response.url)
        XCTAssertEqual(receivedValues.response.statusCode, response.statusCode)
    }
    
    // MARK: - Helpers
    
    private func resultValuesForGetFromUrl(
        with values: (data: Data?, response: URLResponse?, error: Error?),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultForGetFromUrl(with: values, file: file, line: line)
        
        switch result {
        case let .success((data, response)):
            return (data, response)
        default:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultErrorForGetFromUrl(
        with values: (data: Data?, response: URLResponse?, error: Error?)? = nil,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        let result = resultForGetFromUrl(with: values, taskHandler: taskHandler, file: file, line: line)
        
        switch result {
        case let .failure(error):
            return error
        default:
            XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultForGetFromUrl(
        with values: (data: Data?, response: URLResponse?, error: Error?)?,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) -> HTTPClient.Result {
        values.map { URLProtocolStub.stub(data: $0, response: $1, error: $2) }
        
        let sut = makeSUT(testCase: self, file: file, line: line)
        let exp = expectation(description: "Wait for request")
        
        var receivedResult: HTTPClient.Result!
        
        let task = sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }
        taskHandler(task)
        
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
}

class URLSessionHTTPClientPOSTTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.removeStub()
    }
    
    func test_postToURL_performsPOSTRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        let bodyData = anyData()
        
        URLProtocolStub.observerRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.httpBodyData, bodyData)
            exp.fulfill()
        }
        
        makeSUT(testCase: self).post(to: url, body: bodyData) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_cancelPostToURLTask_cancelsURLRequest() throws {
        let receivedError = try XCTUnwrap(resultErrorForPostToUrl(taskHandler: { $0.cancel() }) as? NSError)

        XCTAssertEqual(receivedError.code, URLError.cancelled.rawValue)
    }
    
    func test_postToURL_failsOnRequestError() throws {
        let requestError = anyNSError()
        
        let receivedError = try XCTUnwrap(resultErrorForPostToUrl(with: (data: nil, response: nil, error: requestError)))
        
        XCTAssertEqual((receivedError as NSError).domain, requestError.domain)
        XCTAssertEqual((receivedError as NSError).code, requestError.code)
    }
    
    func test_postToURL_failsOnAllInvalidRepresentations() {
        XCTAssertNotNil(resultErrorForPostToUrl(with: (data: nil, response: nil, error: nil)))
        XCTAssertNotNil(resultErrorForPostToUrl(with: (data: nil, response: nonHTTPURLResponse(), error: nil)))
        XCTAssertNotNil(resultErrorForPostToUrl(with: (data: anyData(), response: nil, error: nil)))
        XCTAssertNotNil(resultErrorForPostToUrl(with: (data: anyData(), response: nil, error: anyNSError())))
        XCTAssertNotNil(resultErrorForPostToUrl(with: (data: nil, response: nonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorForPostToUrl(with: (data: nil, response: anyHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorForPostToUrl(with: (data: anyData(), response: nonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorForPostToUrl(with: (data: anyData(), response: anyHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorForPostToUrl(with: (data: anyData(), response: nonHTTPURLResponse(), error: nil)))
    }
    
    func test_postToURL_succeedsOnHTTPURLResponseWithData() throws {
        let data = anyData()
        let response = anyHTTPURLResponse()
        
        let receivedValues = try XCTUnwrap(resultValuesForPostToUrl(with: (data: data, response: response, error: nil)))
        
        XCTAssertEqual(receivedValues.data, data)
        XCTAssertEqual(receivedValues.response.url, response.url)
        XCTAssertEqual(receivedValues.response.statusCode, response.statusCode)
    }
    
    func test_postToURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() throws {
        let response = anyHTTPURLResponse()
        
        let receivedValues = try XCTUnwrap(resultValuesForPostToUrl(with: (data: nil, response: response, error: nil)))
        
        let emptyData = Data()
        XCTAssertEqual(receivedValues.data, emptyData)
        XCTAssertEqual(receivedValues.response.url, response.url)
        XCTAssertEqual(receivedValues.response.statusCode, response.statusCode)
    }
    
    // MARK: - Helpers
    
    private func resultValuesForPostToUrl(
        with values: (data: Data?, response: URLResponse?, error: Error?),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultForPostToUrl(with: values, file: file, line: line)
        
        switch result {
        case let .success((data, response)):
            return (data, response)
        default:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultErrorForPostToUrl(
        with values: (data: Data?, response: URLResponse?, error: Error?)? = nil,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        let result = resultForPostToUrl(with: values, taskHandler: taskHandler, file: file, line: line)
        
        switch result {
        case let .failure(error):
            return error
        default:
            XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultForPostToUrl(
        with values: (data: Data?, response: URLResponse?, error: Error?)?,
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) -> HTTPClient.Result {
        values.map { URLProtocolStub.stub(data: $0, response: $1, error: $2) }
        
        let sut = makeSUT(testCase: self, file: file, line: line)
        let exp = expectation(description: "Wait for request")
        
        var receivedResult: HTTPClient.Result!
        
        let task = sut.post(to: anyURL(), body: anyData()) { result in
            receivedResult = result
            exp.fulfill()
        }
        taskHandler(task)
        
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
}

private func makeSUT(testCase: XCTestCase, file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    let session = URLSession(configuration: configuration)
    let sut = URLSessionHTTPClient(session: session)
    testCase.trackForMemoryLeaks(sut, file: file, line: line)
    return sut
}

private func nonHTTPURLResponse() -> URLResponse {
    URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
}

private func anyHTTPURLResponse() -> HTTPURLResponse {
    HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
}

class URLProtocolStub: URLProtocol {
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
        let requestObserver: ((URLRequest) -> Void)?
    }
    
    private static var stub: Stub?
    
    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        stub = Stub(data: data, response: response, error: error, requestObserver: nil)
    }
    
    static func observerRequests(observer: @escaping (URLRequest) -> Void) {
        stub = Stub(data: nil, response: nil, error: nil, requestObserver: observer)
    }
    
    static func removeStub() {
        stub = nil
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        guard let stub = URLProtocolStub.stub else { return }
        
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
        
        stub.requestObserver?(request)
    }
    
    override func stopLoading() {}
}

extension URLRequest {
    var httpBodyData: Data? {
        guard let stream = httpBodyStream else { return httpBody }
        
        let bufferSize = 1024
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        
        stream.open()
        
        while stream.hasBytesAvailable {
            let length = stream.read(&buffer, maxLength: bufferSize)
            
            if length == 0 { break }
            
            data.append(&buffer, count: length)
        }
        
        stream.close()
        
        return data
    }
}
