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
    
    enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    init(url: URL, httpClient: HTTPClient) {
        self.url = url
        self.httpClient = httpClient
    }
    
    func loadImageData(from url: URL, completion: @escaping (ImageDataLoader.Result) -> Void) -> ImageDataLoaderTask {
        httpClient.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                completion(.failure(Error.invalidData))
                
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
        
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
    
    func test_loadImageDataFromURLTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-concrete-url.com")!
        let (sut, httpClient) = makeSUT(url: url)
        
        _ = sut.loadImageData(from: url) { _ in }
        _ = sut.loadImageData(from: url) { _ in }
        
        XCTAssertEqual(httpClient.requestedURLs, [url, url])
    }
    
    func test_loadImageDataFromURL_deliversConnectivityErrorOnClientError() {
        let (sut, httpClient) = makeSUT()
        let clientError = anyNSError()
        
        expect(sut, toCompleteWith: failure(.connectivity), when: {
            httpClient.complete(with: clientError)
        })
    }
    
    func test_loadImageDataFromURL_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let (sut, httpClient) = makeSUT()
        let responseCodes = [199, 201, 300, 400, 401, 404, 500]
        
        responseCodes.enumerated().forEach { index, responseCode in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                httpClient.complete(withStatusCode: responseCode, data: anyData(), at: index)
            })
        }
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
    
    private func failure(_ error: RemoteImageDataLoader.Error) -> ImageDataLoader.Result {
        .failure(error)
    }
    
    private func expect(
        _ sut: RemoteImageDataLoader,
        toCompleteWith expectedResult: ImageDataLoader.Result,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let url = URL(string: "https://a-concrete-url.com")!
        let exp = expectation(description: "Wait for load completion")
        
        _ = sut.loadImageData(from: url) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.failure(receivedError as RemoteImageDataLoader.Error), .failure(expectedError as RemoteImageDataLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail()
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
}
