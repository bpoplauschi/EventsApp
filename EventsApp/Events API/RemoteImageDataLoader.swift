//
//  RemoteImageDataLoader.swift
//  EventsApp
//
//  Created by Bogdan on 19.07.2022.
//

import Foundation

public final class RemoteImageDataLoader {
    private let httpClient: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    private final class HTTPClientTaskWrapper: ImageDataLoaderTask {
        private var completion: ((ImageDataLoader.Result) -> Void)?
        
        var wrapped: HTTPClientTask?
        
        init(_ completion: @escaping (ImageDataLoader.Result) -> Void) {
            self.completion = completion
        }
        
        func complete(with result: ImageDataLoader.Result) {
            completion?(result)
        }
        
        func cancel() {
            completion = nil
            wrapped?.cancel()
        }
    }
    
    public func loadImageData(from url: URL, completion: @escaping (ImageDataLoader.Result) -> Void) -> ImageDataLoaderTask {
        let task = HTTPClientTaskWrapper(completion)
        task.wrapped = httpClient.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            task.complete(with: result
                .mapError { _ in Error.connectivity }
                .flatMap { (data, response) in
                    let isValidResponse = response.isSuccessful && !data.isEmpty
                    return isValidResponse ? .success(data) : .failure(Error.invalidData)
                }
            )
        }
        
        return task
    }
}
