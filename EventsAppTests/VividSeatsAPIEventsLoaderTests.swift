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
    
    init(url: URL, httpClient: HTTPClient) {
        self.url = url
        self.httpClient = httpClient
    }
}

class VividSeatsAPIEventsLoaderTests: XCTestCase {
    func test_init_doesNotRequestData() {
        let (_, httpClient) = makeSUT()
        
        XCTAssertTrue(httpClient.requestedURLs.isEmpty)
    }
    
    private func makeSUT(url: URL = URL(string: "http://a-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: VividSeatsAPIEventsLoader, httpClient: HTTPClientSpy) {
        let httpClient = HTTPClientSpy()
        let sut = VividSeatsAPIEventsLoader(url: url, httpClient: httpClient)
        return (sut, httpClient)
    }
}

private class HTTPClientSpy: HTTPClient {
    var requestedURLs: [URL] = []
    
    func post(to url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
    }
}
