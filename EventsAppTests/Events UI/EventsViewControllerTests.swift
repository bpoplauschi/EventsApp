//
//  EventsViewControllerTests.swift
//  EventsAppTests
//
//  Created by Bogdan on 23.07.2022.
//

import EventsApp
import UIKit
import XCTest

class EventsViewController: UITableViewController {
    private var loader: EventsLoader?
    
    convenience init(loader: EventsLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refresh()
    }
    
    @objc private func refresh() {
        refreshControl?.beginRefreshing()
        loader?.load(startDate: Date(), endDate: Date()) { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}

class EventsViewControllerTests: XCTestCase {
    func test_loadEventsActions_requestEventsFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadCallCount, 0, "Expected no load requests before view is loaded")
        
        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected a load request once view is loaded")
        
        sut.simulateUserInitiatedRefresh()
        XCTAssertEqual(loader.loadCallCount, 2, "Expected another load request once user initiates a load")
        
        sut.simulateUserInitiatedRefresh()
        XCTAssertEqual(loader.loadCallCount, 3, "Expected a third load request once user initiates another load")
    }
    
    func test_loadingIndicator_isVisibleWhenLoadingEvents() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")

        loader.complete(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading is completed")
        
        sut.simulateUserInitiatedRefresh()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a refresh")
        
        loader.complete(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated refresh is completed")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: EventsViewController, loader: EventsLoaderSpy) {
        let loader = EventsLoaderSpy()
        let sut = EventsViewController(loader: loader)
        trackForMemoryLeaks(loader)
        trackForMemoryLeaks(sut)
        return (sut, loader)
    }
    
    private class EventsLoaderSpy: EventsLoader {
        private var completions: [(EventsLoader.Result) -> Void] = []
        var loadCallCount: Int { completions.count }
        
        func load(startDate: Date, endDate: Date, completion: @escaping (EventsLoader.Result) -> Void) {
            completions.append(completion)
        }
        
        func complete(at index: Int) {
            completions[index](.success([]))
        }
    }
}

private extension EventsViewController {
    func simulateUserInitiatedRefresh() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
