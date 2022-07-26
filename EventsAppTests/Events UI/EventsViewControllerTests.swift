//
//  EventsViewControllerTests.swift
//  EventsAppTests
//
//  Created by Bogdan on 23.07.2022.
//

import EventsApp
import UIKit
import XCTest

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
    
    func test_loadEventsCompletion_rendersSuccessfullyLoadedEvents() throws {
        let event0 = Event(name: "a name", location: "a location", dateInterval: "a date interval", count: 1, imageURL: URL(string: "http://a-specific-url.com")!)
        let event1 = Event(name: "another name", location: "another location", dateInterval: "another date interval", count: 0, imageURL: nil)
        let event2 = Event(name: "a name", location: "", dateInterval: "", count: 1, imageURL: URL(string: "http://another-specific-url.com")!)
        let event3 = Event(name: "", location: "", dateInterval: "", count: 0, imageURL: nil)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])
        
        loader.complete(with: [event0], at: 0)
        assertThat(sut, isRendering: [event0])
        
        sut.simulateUserInitiatedRefresh()
        loader.complete(with: [event0, event1, event2, event3], at: 1)
        assertThat(sut, isRendering: [event0, event1, event2, event3])
    }
    
    func test_loadEventsCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let event0 = Event(name: "a name", location: "a location", dateInterval: "a date interval", count: 1, imageURL: URL(string: "http://a-specific-url.com")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.complete(with: [event0], at: 0)
        assertThat(sut, isRendering: [event0])
        
        sut.simulateUserInitiatedRefresh()
        loader.complete(withErrorAt: 1)
        assertThat(sut, isRendering: [event0])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: EventsViewController, loader: EventsLoaderSpy) {
        let loader = EventsLoaderSpy()
        let sut = EventsViewController(loader: loader)
        trackForMemoryLeaks(loader)
        trackForMemoryLeaks(sut)
        return (sut, loader)
    }
    
    private func assertThat(
        _ sut: EventsViewController,
        isRendering events: [Event],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard sut.numberOfRenderedEventViews() == events.count else {
            return XCTFail("Expected \(events.count) event cells, got \(sut.numberOfRenderedEventViews()) instead", file: file, line: line)
        }
        
        events.enumerated().forEach { index, event in
            assertThat(sut, hasViewConfiguredFor: event, at: index)
        }
    }
    
    private func assertThat(
        _ sut: EventsViewController,
        hasViewConfiguredFor event: Event,
        at index: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let view = sut.eventView(at: index)
        
        guard let cell = view as? EventCell else {
            return XCTFail("Expected \(EventCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
        }
        
        XCTAssertEqual(cell.nameText, event.name, "Expected name text to be \(String(describing: event.name)) for cell at index (\(index))", file: file, line: line)
        XCTAssertEqual(cell.locationText, event.location, "Expected location text to be \(String(describing: event.location)) for cell at index (\(index))", file: file, line: line)
        XCTAssertEqual(cell.dateIntervalText, event.dateInterval, "Expected dateInterval text to be \(String(describing: event.dateInterval)) for cell at index (\(index))", file: file, line: line)
        XCTAssertEqual(cell.countText, "\(event.count) events", "Expected events count text to be \(String(describing: "\(event.count) events")) for cell at index (\(index))", file: file, line: line)
    }
    
    private class EventsLoaderSpy: EventsLoader {
        private var completions: [(EventsLoader.Result) -> Void] = []
        var loadCallCount: Int { completions.count }
        
        func load(startDate: Date, endDate: Date, completion: @escaping (EventsLoader.Result) -> Void) {
            completions.append(completion)
        }
        
        func complete(with events: [Event] = [], at index: Int) {
            completions[index](.success(events))
        }
        
        func complete(withErrorAt index: Int) {
            let error = NSError(domain: "an error", code: 0)
            completions[index](.failure(error))
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
    
    func numberOfRenderedEventViews() -> Int {
        tableView.numberOfRows(inSection: eventsSection)
    }
    
    func eventView(at row: Int) -> UITableViewCell? {
        let dataSource = tableView.dataSource
        let index = IndexPath(row: row, section: eventsSection)
        return dataSource?.tableView(tableView, cellForRowAt: index)
    }
    
    private var eventsSection: Int { 0 }
}

private extension EventCell {
    var nameText: String? { nameLabel.text }
    var locationText: String? { locationLabel.text }
    var dateIntervalText: String? { dateIntervalLabel.text }
    var countText: String? { countLabel.text }
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
