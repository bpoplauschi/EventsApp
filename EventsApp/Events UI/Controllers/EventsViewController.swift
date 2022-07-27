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
    private var imageLoadingTasks: [IndexPath: ImageDataLoaderTask] = [:]
    
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
        let cellModel = tableModel[indexPath.row]
        let cell = EventCell()
        cell.nameLabel.text = cellModel.name
        cell.locationLabel.text = cellModel.location
        cell.dateIntervalLabel.text = cellModel.dateInterval
        cell.countLabel.text = "\(cellModel.count) events"
        cell.eventImageView.image = nil
        cell.imageContainer.startShimmering()
        if let imageURL = cellModel.imageURL {
            imageLoadingTasks[indexPath] = imageLoader?.loadImageData(from: imageURL) { [weak cell] result in
                let data = try? result.get()
                cell?.eventImageView.image = data.map(UIImage.init) ?? nil
                cell?.imageContainer.stopShimmering()
            }
        }
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelImageLoadingTask(forRowAt: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let cellModel = tableModel[indexPath.row]
            if let imageURL = cellModel.imageURL {
                imageLoadingTasks[indexPath] = imageLoader?.loadImageData(from: imageURL) { _ in }
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cancelImageLoadingTask(forRowAt: indexPath)
        }
    }
    
    private func cancelImageLoadingTask(forRowAt indexPath: IndexPath) {
        imageLoadingTasks[indexPath]?.cancel()
        imageLoadingTasks[indexPath] = nil
    }
}
