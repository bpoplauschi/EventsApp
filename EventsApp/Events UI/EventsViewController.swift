//
//  EventsViewController.swift
//  EventsApp
//
//  Created by Bogdan on 25.07.2022.
//

import UIKit

public final class EventsViewController: UITableViewController {
    private var eventsLoader: EventsLoader?
    private var imageLoader: ImageDataLoader?
    private var tableModel: [Event] = []
    private var imageLoadingTasks: [IndexPath: ImageDataLoaderTask] = [:]
    
    public convenience init(eventsLoader: EventsLoader, imageLoader: ImageDataLoader) {
        self.init()
        self.eventsLoader = eventsLoader
        self.imageLoader = imageLoader
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refresh()
    }
    
    @objc private func refresh() {
        refreshControl?.beginRefreshing()
        eventsLoader?.load(startDate: Date(), endDate: Date()) { [weak self] result in
            if let events = try? result.get() {
                self?.tableModel = events
                self?.tableView.reloadData()
            }
            self?.refreshControl?.endRefreshing()
        }
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
        imageLoadingTasks[indexPath]?.cancel()
        imageLoadingTasks[indexPath] = nil
    }
}
