//
//  EventsRefreshController.swift
//  EventsApp
//
//  Created by Bogdan on 27.07.2022.
//

import UIKit

final class EventsRefreshController: NSObject {
    @IBOutlet private var view: UIRefreshControl?
    
    var eventsLoader: EventsLoader?
    
    var onRefresh: (([Event]) -> Void)?
        
    @IBAction func refresh() {
        view?.beginRefreshing()
        eventsLoader?.load(startDate: Date(), endDate: Date()) { [weak self] result in
            if let events = try? result.get() {
                self?.onRefresh?(events)
            }
            self?.view?.endRefreshing()
        }
    }
}
