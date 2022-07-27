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
    
    init(model: Event, imageLoader: ImageDataLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }
    
    func view() -> UITableViewCell {
        let cell = EventCell()
        cell.nameLabel.text = model.name
        cell.locationLabel.text = model.location
        cell.dateIntervalLabel.text = model.dateInterval
        cell.countLabel.text = "\(model.count) events"
        cell.eventImageView.image = nil
        cell.imageContainer.startShimmering()
        if let imageURL = model.imageURL {
            self.imageLoadingTask = imageLoader.loadImageData(from: imageURL) { [weak cell] result in
                let data = try? result.get()
                cell?.eventImageView.image = data.map(UIImage.init) ?? nil
                cell?.imageContainer.stopShimmering()
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
    }
}
