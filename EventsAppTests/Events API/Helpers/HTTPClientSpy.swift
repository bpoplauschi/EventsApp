//
//  HTTPClientSpy.swift
//  EventsAppTests
//
//  Created by Bogdan on 19.07.2022.
//

import Foundation
import EventsApp
import XCTest

final class HTTPClientSpy: HTTPClient {
    private struct Task: HTTPClientTask {
        let callback: () -> Void
        func cancel() { callback() }
    }
    
    struct HTTPMessage {
        enum HTTPMethod: String {
            case get = "GET"
            case post = "POST"
        }
        
        let url: URL
        let method: HTTPMethod
        let body: Data?
        let completion: (HTTPClient.Result) -> Void
    }
    
    var messages: [HTTPMessage] = []
    
    private (set) var cancelledURLs: [URL] = []
    
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        messages.append(HTTPMessage(url: url, method: .get, body: nil, completion: completion))
        return Task { [weak self] in
            self?.cancelledURLs.append(url)
        }
    }
    
    func post(to url: URL, body: Data, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        messages.append(HTTPMessage(url: url, method: .post, body: body, completion: completion))
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

func assertThat(httpClient: HTTPClientSpy, receivedTwoMessagesWithURL url: URL, method: String, file: StaticString = #file, line: UInt = #line) throws {
    XCTAssertEqual(httpClient.messages.count, 2, "Expected the http client spy to have receive two message, got \(httpClient.messages.count) instead", file: file, line: line)
    
    let firstMessage = try XCTUnwrap(httpClient.messages.first)
    XCTAssertEqual(firstMessage.url, url, "1 Expected \(url) got \(firstMessage.url) instead", file: file, line: line)
    XCTAssertEqual(firstMessage.method.rawValue, method, "1 Expected \(method) got \(firstMessage.method) instead", file: file, line: line)
    
    let lastMessage = try XCTUnwrap(httpClient.messages.last)
    XCTAssertEqual(lastMessage.url, url, "2 Expected \(url) got \(firstMessage.url) instead", file: file, line: line)
    XCTAssertEqual(lastMessage.method.rawValue, method, "2 Expected \(method) got \(firstMessage.method) instead", file: file, line: line)
}

func assertThat(httpClient: HTTPClientSpy, receivedOneMessageWithURL url: URL, method: String, body: [String: String]?, file: StaticString = #file, line: UInt = #line) throws {
    XCTAssertEqual(httpClient.messages.count, 1, "Expected the http client spy to have receive one message, got \(httpClient.messages.count) instead", file: file, line: line)
    
    let httpMessage = try XCTUnwrap(httpClient.messages.first)
    
    XCTAssertEqual(httpMessage.url, url, "Expected \(url) got \(httpMessage.url) instead", file: file, line: line)
    XCTAssertEqual(httpMessage.method.rawValue, method, "Expected \(method) got \(httpMessage.method) instead", file: file, line: line)
    
    if let body = body {
        let bodyData = try XCTUnwrap(httpMessage.body)
        let bodyDict = try JSONDecoder().decode([String: String].self, from: bodyData)
        
        body.forEach { key, value in
            XCTAssertEqual(bodyDict[key], value, "Expected body key \(key) with value \(value) got \(String(describing: bodyDict[key])) instead", file: file, line: line)
        }
    } else {
        XCTAssertNil(httpMessage.body, "Expected body nil, got \(String(describing: httpMessage.body)) instead")
    }
}
