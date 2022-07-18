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
    let topLabel: String
    let middleLabel: String
    let bottomLabel: String
    let eventCount: Int
    let image: String
    let targetId: Int
    let targetType: String
    let entityId: Int
    let entityType: String
    let startDate: Int64
    let rank: Int
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
                if response.statusCode == 200,
                    let root = try? JSONDecoder().decode([VividSeatsAPIEvent].self, from: data) {
                    completion(.success(root.map({ apiEvent in
                        Event(name: apiEvent.topLabel, location: apiEvent.middleLabel, dateInterval: apiEvent.bottomLabel, count: apiEvent.eventCount, imageURL: URL(string: apiEvent.image))
                    })))
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
    
    func test_load_deliversEventsOn200HTTPResponseWithEventsJSON() {
        let (sut, httpClient) = makeSUT()
        let event1 = makeEvent(name: "a name", location: "a location", dateInterval: "a date interval", count: 1, imageURL: nil)
        let event2 = makeEvent(name: "another name", location: "another location", dateInterval: "another date interval", count: 2, imageURL: URL(string: "http://any-url.com")!)
        let events = [event1.event, event2.event]
        
        expect(sut, toCompleteWith: .success(events), when: {
            let jsonData = makeEventsJSONData([event1.json, event2.json])
            httpClient.complete(withStatusCode: 200, data: jsonData)
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
    
    private func makeEvent(name: String, location: String, dateInterval: String, count: Int, imageURL: URL?) -> (event: Event, json: JSON) {
        let event = Event(name: name, location: location, dateInterval: dateInterval, count: count, imageURL: imageURL)
        
        let json = [
            "topLabel": name,
            "middleLabel": location,
            "bottomLabel": dateInterval,
            "eventCount": count,
            "image": imageURL?.absoluteString ?? "",
            "targetId": 2119461,
            "targetType": "EVENT",
            "entityId": 9420,
            "entityType": "PERFORMER",
            "startDate": 1495242000000,
            "rank": 260
        ].compactMapValues { $0 }
        
        return (event, json)
    }
    
    private func makeEventsJSONData(_ events: [JSON]) -> Data {
        print(events)
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
