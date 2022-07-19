//
//  RemoteImageDataLoaderTests.swift
//  EventsAppTests
//
//  Created by Bogdan on 19.07.2022.
//

import EventsApp
import XCTest

class RemoteImageDataLoader {
    private let url: URL
    private let httpClient: HTTPClient
    
    init(url: URL, httpClient: HTTPClient) {
        self.url = url
        self.httpClient = httpClient
    }
}

class RemoteImageDataLoaderTests: XCTestCase {
    func test_init_doesNotPerformAnyURLRequest() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        url: URL = anyURL(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: RemoteImageDataLoader, httpClient: HTTPClientSpy) {
        let httpClient = HTTPClientSpy()
        let sut = RemoteImageDataLoader(url: url, httpClient: httpClient)
        trackForMemoryLeaks(httpClient)
        trackForMemoryLeaks(sut)
        return (sut, httpClient)
    }
}
