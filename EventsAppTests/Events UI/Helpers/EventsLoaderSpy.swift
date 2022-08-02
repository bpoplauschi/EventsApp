//
//  EventsLoaderSpy.swift
//  EventsAppTests
//
//  Created by Bogdan on 02.08.2022.
//

import EventsApp
import XCTest

final class EventsLoaderSpy: EventsLoader, ImageDataLoader {
    // MARK: - EventsLoader
    private struct Request {
        let startDate: Date
        let endDate: Date
        let completion: (EventsLoader.Result) -> Void
    }
    
    private var eventsRequests: [Request] = []
    
    var loadCallCount: Int { eventsRequests.count }
    
    func load(startDate: Date, endDate: Date, completion: @escaping (EventsLoader.Result) -> Void) {
        eventsRequests.append(Request(startDate: startDate, endDate: endDate, completion: completion))
    }
    
    func complete(with events: [Event] = [], at index: Int) {
        eventsRequests[index].completion(.success(events))
    }
    
    func completeWithError(at index: Int) {
        let error = NSError(domain: "an error", code: 0)
        eventsRequests[index].completion(.failure(error))
    }
    
    func dates(at index: Int = 0) -> (startDate: Date, endDate: Date) {
        let request = eventsRequests[index]
        return (request.startDate, request.endDate)
    }
    
    // MARK: - ImageDataLoader
    private struct ImageDataLoaderTaskSpy: ImageDataLoaderTask {
        let cancelCallback: () -> Void
        func cancel() {
            cancelCallback()
        }
    }
    
    private var imageRequests: [(url: URL, completion: (ImageDataLoader.Result) -> Void)] = []
    var loadedImageURLs: [URL] { imageRequests.map { $0.url } }
    private(set) var cancelledImageURLs: [URL] = []
    
    func loadImageData(from url: URL, completion: @escaping (ImageDataLoader.Result) -> Void) -> ImageDataLoaderTask {
        imageRequests.append((url, completion))
        return ImageDataLoaderTaskSpy { [weak self] in
            self?.cancelledImageURLs.append(url)
        }
    }
    
    func completeImageLoading(with imageData: Data = Data(), at index: Int = 0) {
        imageRequests[index].completion(.success(imageData))
    }
    
    func completeImageLoadingWithError(at index: Int = 0) {
        let error = NSError(domain: "an error", code: 0)
        imageRequests[index].completion(.failure(error))
    }
}
