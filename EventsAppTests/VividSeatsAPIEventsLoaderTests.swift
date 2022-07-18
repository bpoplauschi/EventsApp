//
//  VividSeatsAPIEventsLoaderTests.swift
//  EventsAppTests
//
//  Created by Bogdan on 14.07.2022.
//

import EventsApp
import XCTest

protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    
    func post(to url: URL, completion: @escaping (Result) -> Void)
}

class VividSeatsAPIEventsLoader {
    private let url: URL
    private let httpClient: HTTPClient
    
    typealias Result = EventsLoader.Result
    
    init(url: URL, httpClient: HTTPClient) {
        self.url = url
        self.httpClient = httpClient
    }
    
    func load(completion: @escaping (Result) -> Void) {
        httpClient.post(to: url) { result in }
    }
}

class VividSeatsAPIEventsLoaderTests: XCTestCase {
    func test_init_doesNotRequestData() {
        let (_, httpClient) = makeSUT()
        
        XCTAssertTrue(httpClient.requestedURLs.isEmpty)
    }
    
    func test_load_requestsData() {
        let url = URL(string: "https://a-concrete-url.com")!
        let (sut, httpClient) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(httpClient.requestedURLs, [url])
    }
    
    private func makeSUT(url: URL = URL(string: "http://a-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: VividSeatsAPIEventsLoader, httpClient: HTTPClientSpy) {
        let httpClient = HTTPClientSpy()
        let sut = VividSeatsAPIEventsLoader(url: url, httpClient: httpClient)
        trackForMemoryLeaks(httpClient)
        trackForMemoryLeaks(sut)
        return (sut, httpClient)
    }
}

private class HTTPClientSpy: HTTPClient {
    var requestedURLs: [URL] = []
    
    func post(to url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        requestedURLs.append(url)
    }
}
