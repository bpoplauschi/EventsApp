//
//  EventsRefreshController.swift
//  EventsApp
//
//  Created by Bogdan on 27.07.2022.
//

import UIKit

final class EventsRefreshController: NSObject {
    private(set) lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
    
    private var eventsLoader: EventsLoader
    
    var onRefresh: (([Event]) -> Void)?
    
    init(eventsLoader: EventsLoader) {
        self.eventsLoader = eventsLoader
    }
    
    @objc func refresh() {
        view.beginRefreshing()
        eventsLoader.load(startDate: Date(), endDate: Date()) { [weak self] result in
            if let events = try? result.get() {
                self?.onRefresh?(events)
            }
            self?.view.endRefreshing()
        }
    }
}
