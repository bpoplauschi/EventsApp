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
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (Result) -> Void) {
        let task = session.dataTask(with: url) { data, response, error in
            switch (data, response, error) {
            case let (_, _, .some(error)):
                completion(.failure(error))
            default:
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }
        task.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
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
        
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let requestError = anyNSError()
        
        URLProtocolStub.stub(data: nil, response: nil, error: requestError)
        
        let sut = makeSUT()
        let exp = expectation(description: "Wait for request")
        
        var receivedResult: HTTPClient.Result!
        sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        switch receivedResult {
        case let .failure(error):
            XCTAssertEqual((error as NSError).domain, requestError.domain)
            XCTAssertEqual((error as NSError).code, requestError.code)
            
        default:
            XCTFail("Expected failure, got \(String(describing: receivedResult)) instead")
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
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
