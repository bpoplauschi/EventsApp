//
//  EventsViewControllerTests.swift
//  EventsAppTests
//
//  Created by Bogdan on 23.07.2022.
//

import EventsApp
import UIKit
import XCTest

class EventsViewController {
    init(loader: EventsLoader) {
    }
}

class EventsViewControllerTests: XCTestCase {
    func test_init_doesNotLoadEvents() {
        let loader = EventsLoaderSpy()
        _ = EventsViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    // MARK: - Helpers
    
    class EventsLoaderSpy: EventsLoader {
        private(set) var loadCallCount: Int = 0
        
        func load(startDate: Date, endDate: Date, completion: @escaping (EventsLoader.Result) -> Void) {
            loadCallCount += 1
        }
    }
}
