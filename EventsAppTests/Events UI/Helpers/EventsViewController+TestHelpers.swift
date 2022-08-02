//
//  EventsViewController+TestHelpers.swift
//  EventsAppTests
//
//  Created by Bogdan on 02.08.2022.
//

import EventsApp
import UIKit

extension EventsViewController {
    func simulateUserInitiatedRefresh() {
        refreshControl?.simulatePullToRefresh()
    }
    
    @discardableResult
    func simulateEventImageViewVisible(at index: Int) -> EventCell? {
        return eventView(at: index) as? EventCell
    }
    
    func simulateEventImageViewNearVisible(at row: Int) {
        let dataSource = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: eventsSection)
        dataSource?.tableView(tableView, prefetchRowsAt: [index])
    }
    
    @discardableResult
    func simulateEventImageViewNotVisible(at row: Int) -> EventCell? {
        let view = simulateEventImageViewVisible(at: row)
        
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: eventsSection)
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: index)
        return view
    }
    
    func simulateEventImageViewNotNearVisible(at row: Int) {
        simulateEventImageViewNearVisible(at: row)
        
        let dataSource = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: eventsSection)
        dataSource?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
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

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
