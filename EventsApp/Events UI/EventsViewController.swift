//
//  EventsViewController.swift
//  EventsApp
//
//  Created by Bogdan on 25.07.2022.
//

import UIKit

public final class EventsViewController: UITableViewController {
    private var loader: EventsLoader?
    private var tableModel: [Event] = []
    
    public convenience init(loader: EventsLoader) {
        self.init()
        self.loader = loader
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refresh()
    }
    
    @objc private func refresh() {
        refreshControl?.beginRefreshing()
        loader?.load(startDate: Date(), endDate: Date()) { [weak self] result in
            switch result {
            case let .success(events):
                self?.tableModel = events
                self?.tableView.reloadData()
                self?.refreshControl?.endRefreshing()
                
            case .failure:
                break
            }
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
        return cell
    }
}
