//
//  EventsViewController.swift
//  EventsApp
//
//  Created by Bogdan on 25.07.2022.
//

import UIKit

public final class EventsViewController: UITableViewController, UITableViewDataSourcePrefetching {
    private var refreshController: EventsRefreshController?
    private var imageLoader: ImageDataLoader?
    private var tableModel: [Event] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    private var cellControllers: [IndexPath: EventCellController] = [:]
    
    public convenience init(eventsLoader: EventsLoader, imageLoader: ImageDataLoader) {
        self.init()
        self.refreshController = EventsRefreshController(eventsLoader: eventsLoader)
        self.imageLoader = imageLoader
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = refreshController?.view
        refreshController?.onRefresh = { [weak self] events in
            self?.tableModel = events
        }
        tableView.prefetchDataSource = self
        refreshController?.refresh()
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellController(forRowAt: indexPath).view()
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        removeCellController(forRowAt: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(forRowAt: indexPath).preload()
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(removeCellController)
    }
    
    private func cellController(forRowAt indexPath: IndexPath) -> EventCellController {
        let cellModel = tableModel[indexPath.row]
        let cellController = EventCellController(model: cellModel, imageLoader: imageLoader!)
        cellControllers[indexPath] = cellController
        return cellController
    }
    
    private func removeCellController(forRowAt indexPath: IndexPath) {
        cellControllers[indexPath] = nil
    }
}
