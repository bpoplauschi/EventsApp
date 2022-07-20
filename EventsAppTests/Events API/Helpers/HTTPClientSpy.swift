//
//  HTTPClientSpy.swift
//  EventsAppTests
//
//  Created by Bogdan on 19.07.2022.
//

import Foundation
import EventsApp

final class HTTPClientSpy: HTTPClient {
    private struct Task: HTTPClientTask {
        let callback: () -> Void
        func cancel() { callback() }
    }
    
    private var messages: [(url: URL, body: Data?, completion: (HTTPClient.Result) -> Void)] = []
    private (set) var cancelledURLs: [URL] = []
    
    var requestedURLs: [URL] { messages.map { $0.url } }
    
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        messages.append((url, nil, completion))
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }
    
    func post(to url: URL, body: Data, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        messages.append((url, body, completion))
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
        let response = HTTPURLResponse(url: messages[index].url, statusCode: code, httpVersion: nil, headerFields: nil)!
        messages[index].completion(.success((data, response)))
    }
}
