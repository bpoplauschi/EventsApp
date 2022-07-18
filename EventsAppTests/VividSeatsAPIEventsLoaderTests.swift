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

struct VividSeatsAPIEvent: Decodable {
    
}

class VividSeatsAPIEventsLoader {
    private let url: URL
    private let httpClient: HTTPClient
    
    typealias Result = EventsLoader.Result
    
    enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    init(url: URL, httpClient: HTTPClient) {
        self.url = url
        self.httpClient = httpClient
    }
    
    func load(completion: @escaping (Result) -> Void) {
        httpClient.post(to: url) { result in
            switch result {
            case let .success((data, response)):
                if response.statusCode == 200, let root = try? JSONDecoder().decode([VividSeatsAPIEvent].self, from: data) {
                    completion(.success([]))
                } else {
                    completion(.failure(Error.invalidData))
                }
                
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
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
    
    func test_loadTwice_requestsDataTwice() {
        let url = URL(string: "https://a-concrete-url.com")!
        let (sut, httpClient) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(httpClient.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, httpClient) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            httpClient.complete(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, httpClient) = makeSUT()
        let responseCodes = [199, 201, 300, 400, 401, 404, 500]
        
        responseCodes.enumerated().forEach { index, responseCode in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                let json = makeEventsJSONData([])
                httpClient.complete(withStatusCode: responseCode, data: json, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, httpClient) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            httpClient.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliversNoEventsOn200HTTPResponseWithEmptyListJSON() {
        let (sut, httpClient) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), when: {
            let emptyListJSON = makeEventsJSONData([])
            httpClient.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "http://a-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: VividSeatsAPIEventsLoader, httpClient: HTTPClientSpy) {
        let httpClient = HTTPClientSpy()
        let sut = VividSeatsAPIEventsLoader(url: url, httpClient: httpClient)
        trackForMemoryLeaks(httpClient)
        trackForMemoryLeaks(sut)
        return (sut, httpClient)
    }
    
    private func failure(_ error: VividSeatsAPIEventsLoader.Error) -> VividSeatsAPIEventsLoader.Result {
        .failure(error)
    }
    
    private typealias JSON = [String: Any]
    
    private func makeEventsJSONData(_ events: [JSON]) -> Data {
        let json = events
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(_ sut: VividSeatsAPIEventsLoader, toCompleteWith expectedResult: VividSeatsAPIEventsLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedEvents), .success(expectedEvents)):
                XCTAssertEqual(receivedEvents, expectedEvents, file: file, line: line)
                
            case let (.failure(receivedError as VividSeatsAPIEventsLoader.Error), .failure(expectedError as VividSeatsAPIEventsLoader.Error)):
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

private class HTTPClientSpy: HTTPClient {
    private var messages: [(url: URL, completion: (HTTPClient.Result) -> Void)] = []
    
    var requestedURLs: [URL] { messages.map { $0.url } }
    
    func post(to url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        messages.append((url, completion))
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
        let response = HTTPURLResponse(url: messages[index].url, statusCode: code, httpVersion: nil, headerFields: nil)!
        messages[index].completion(.success((data, response)))
    }
}
