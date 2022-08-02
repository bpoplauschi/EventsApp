//
//  RemoteImageDataLoaderTests.swift
//  EventsAppTests
//
//  Created by Bogdan on 19.07.2022.
//

import EventsApp
import XCTest

class RemoteImageDataLoaderTests: XCTestCase {
    func test_init_doesNotPerformAnyURLRequest() {
        let (_, httpClient) = makeSUT()
        
        XCTAssertTrue(httpClient.messages.isEmpty)
    }
    
    func test_loadImageDataFromURL_requestsDataFromURL() throws {
        let url = URL(string: "https://a-concrete-url.com")!
        let (sut, httpClient) = makeSUT()
        
        _ = sut.loadImageData(from: url) { _ in }
        
        try assertThat(httpClient: httpClient, receivedOneMessageWithURL: url, method: "GET", body: nil)
    }
    
    func test_loadImageDataFromURLTwice_requestsDataFromURLTwice() throws {
        let url = URL(string: "https://a-concrete-url.com")!
        let (sut, httpClient) = makeSUT()
        
        _ = sut.loadImageData(from: url) { _ in }
        _ = sut.loadImageData(from: url) { _ in }
        
        try assertThat(httpClient: httpClient, receivedTwoMessagesWithURL: url, method: "GET")
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
    
    func test_loadImageDataFromURL_deliversInvalidDataErrorOn200HTTPResponseWithEmptyData() {
        let (sut, httpClient) = makeSUT()
        let emptyData = Data()
        
        expect(sut, toCompleteWith: failure(.invalidData), when: {
            httpClient.complete(withStatusCode: 200, data: emptyData)
        })
    }
    
    func test_loadImageDataFromURL_deliversReceivedNonEmptyDataOn200HTTPResponse() {
        let (sut, httpClient) = makeSUT()
        let nonEmptyData = Data("non-empty data".utf8)
        
        expect(sut, toCompleteWith: .success(nonEmptyData), when: {
            httpClient.complete(withStatusCode: 200, data: nonEmptyData)
        })
    }
    
    func test_cancelLoadImageDataURLTask_cancelsClientURLRequest() {
        let (sut, httpClient) = makeSUT()
        let url = URL(string: "https://a-concrete-url.com")!
        
        let task = sut.loadImageData(from: url) { _ in }
        XCTAssertTrue(httpClient.cancelledURLs.isEmpty)
        
        task.cancel()
        
        XCTAssertEqual(httpClient.cancelledURLs, [url])
    }
    
    func test_loadImageDataFromURL_doesNotDeliverResultAfterCancellingTask() {
        let (sut, httpClient) = makeSUT()
        let nonEmptyData = Data("non-empty data".utf8)
        
        var received: [ImageDataLoader.Result] = []
        let task = sut.loadImageData(from: anyURL()) { received.append($0) }
        task.cancel()
        
        httpClient.complete(withStatusCode: 404, data: anyData())
        httpClient.complete(withStatusCode: 200, data: nonEmptyData)
        httpClient.complete(with: anyNSError())
        
        XCTAssertTrue(received.isEmpty, "Expected no results delivered after the task is cancelled")
    }
    
    func test_loadImageDataFromURL_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let httpClient = HTTPClientSpy()
        var sut: RemoteImageDataLoader? = RemoteImageDataLoader(httpClient: httpClient)
        
        var capturedResults: [ImageDataLoader.Result] = []
        _ = sut?.loadImageData(from: anyURL()) { capturedResults.append($0) }
        
        sut = nil
        httpClient.complete(withStatusCode: 200, data: anyData())
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: RemoteImageDataLoader, httpClient: HTTPClientSpy) {
        let httpClient = HTTPClientSpy()
        let sut = RemoteImageDataLoader(httpClient: httpClient)
        trackForMemoryLeaks(httpClient, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
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
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                
            case let (.failure(receivedError as RemoteImageDataLoader.Error), .failure(expectedError as RemoteImageDataLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
}
