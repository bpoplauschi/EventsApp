//
//  EventCellController.swift
//  EventsApp
//
//  Created by Bogdan on 27.07.2022.
//

import UIKit

final class EventCellController {
    private let model: Event
    private let imageLoader: ImageDataLoader
    private var imageLoadingTask: ImageDataLoaderTask?
    private var cell: EventCell?
    
    init(model: Event, imageLoader: ImageDataLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }
    
    func view(in tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell") as! EventCell
        cell.nameLabel.text = model.name
        cell.locationLabel.text = model.location
        cell.dateIntervalLabel.text = model.dateInterval
        cell.countLabel.text = "\(model.count) events"
        cell.eventImageView.image = nil
        cell.imageContainer.startShimmering()
        self.cell = cell
        if let imageURL = model.imageURL {
            imageLoadingTask = imageLoader.loadImageData(from: imageURL) { [weak self] result in
                let data = try? result.get()
                self?.cell?.eventImageView.image = data.map(UIImage.init) ?? nil
                self?.cell?.imageContainer.stopShimmering()
            }
        }
        return cell
    }
    
    func preload() {
        if let imageURL = model.imageURL {
            imageLoadingTask = imageLoader.loadImageData(from: imageURL) { _ in }
        }
    }
    
    func cancelLoad() {
        imageLoadingTask?.cancel()
        releaseCellForReuse()
    }
    
    private func releaseCellForReuse() {
        cell = nil
    }
}
