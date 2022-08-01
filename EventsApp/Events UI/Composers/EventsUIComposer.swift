//
//  EventsUIComposer.swift
//  EventsApp
//
//  Created by Bogdan on 27.07.2022.
//

import Foundation
import UIKit

public final class EventsUIComposer {
    private init() {}
    
    public static func eventsComposedWith(eventsLoader: EventsLoader, imageLoader: ImageDataLoader) -> EventsViewController {
        let bundle = Bundle(for: EventsViewController.self)
        let storyboard = UIStoryboard(name: "Events", bundle: bundle)
        let eventsController = storyboard.instantiateInitialViewController() as! EventsViewController
        let refreshController = eventsController.refreshController!
        
        refreshController.eventsLoader = eventsLoader
        refreshController.onRefresh = adaptEventsToCellControllers(forwardingTo: eventsController, imageLoader: imageLoader)
        
        return eventsController
    }
    
    private static func adaptEventsToCellControllers(forwardingTo controller: EventsViewController, imageLoader: ImageDataLoader) -> ([Event]) -> Void {
        return { [weak controller] events in
            controller?.tableModel = events.map { EventCellController(model: $0, imageLoader: imageLoader) }
        }
    }
}
