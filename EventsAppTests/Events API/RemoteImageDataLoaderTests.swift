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
    
    func loadImageData(from url: URL, completion: @escaping (ImageDataLoader.Result) -> Void) -> ImageDataLoaderTask {
        httpClient.get(from: url) { _ in }
        
        return ImageDataLoaderTaskSpy()
    }
}

private class ImageDataLoaderTaskSpy: ImageDataLoaderTask {
    func cancel() {}
}

class RemoteImageDataLoaderTests: XCTestCase {
    func test_init_doesNotPerformAnyURLRequest() {
        let (_, httpClient) = makeSUT()
        
        XCTAssertTrue(httpClient.requestedURLs.isEmpty)
    }
    
    func test_loadImageDataFromURL_requestsDataFromURL() {
        let url = URL(string: "https://a-concrete-url.com")!
        let (sut, httpClient) = makeSUT(url: url)
        
        _ = sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(httpClient.requestedURLs, [url])
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
