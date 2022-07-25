//
//  EventsViewControllerTests.swift
//  EventsAppTests
//
//  Created by Bogdan on 23.07.2022.
//

import EventsApp
import UIKit
import XCTest

class EventsViewController: UIViewController {
    private var loader: EventsLoader?
    
    convenience init(loader: EventsLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loader?.load(startDate: Date(), endDate: Date()) { _ in }
    }
}

class EventsViewControllerTests: XCTestCase {
    func test_init_doesNotLoadEvents() {
        let loader = EventsLoaderSpy()
        _ = EventsViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func test_viewDidLoad_loadsEvents() {
        let loader = EventsLoaderSpy()
        let sut = EventsViewController(loader: loader)
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    // MARK: - Helpers
    
    class EventsLoaderSpy: EventsLoader {
        private(set) var loadCallCount: Int = 0
        
        func load(startDate: Date, endDate: Date, completion: @escaping (EventsLoader.Result) -> Void) {
            loadCallCount += 1
        }
    }
}
