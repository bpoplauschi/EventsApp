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
    
    private struct Message {
        enum HTTPMethod: String {
            case get = "GET"
            case post = "POST"
        }
        
        let url: URL
        let httpMethod: HTTPMethod
        let httpBody: Data?
        let completion: (HTTPClient.Result) -> Void
    }
    
    private var messages: [Message] = []
    private (set) var cancelledURLs: [URL] = []
    
    var requestedURLs: [URL] { messages.map { $0.url } }
    var requestedMethods: [String] { messages.map { $0.httpMethod.rawValue } }
    var requestedBodies: [Data] { messages.compactMap { $0.httpBody } }
    
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        messages.append(Message(url: url, httpMethod: .get, httpBody: nil, completion: completion))
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }
    
    func post(to url: URL, body: Data, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        messages.append(Message(url: url, httpMethod: .post, httpBody: body, completion: completion))
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
