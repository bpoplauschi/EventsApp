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
    private var eventsRequests: [(EventsLoader.Result) -> Void] = []
    
    var loadCallCount: Int { eventsRequests.count }
    
    func load(startDate: Date, endDate: Date, completion: @escaping (EventsLoader.Result) -> Void) {
        eventsRequests.append(completion)
    }
    
    func complete(with events: [Event] = [], at index: Int) {
        eventsRequests[index](.success(events))
    }
    
    func completeWithError(at index: Int) {
        let error = NSError(domain: "an error", code: 0)
        eventsRequests[index](.failure(error))
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
