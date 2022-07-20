//
//  HTTPClient.swift
//  EventsApp
//
//  Created by Bogdan on 19.07.2022.
//

import Foundation

public protocol HTTPClientTask {
    func cancel()
}

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    
    @discardableResult
    func get(from url: URL, completion: @escaping (Result) -> Void) -> HTTPClientTask
    
    @discardableResult
    func post(to url: URL, completion: @escaping (Result) -> Void) -> HTTPClientTask
}
