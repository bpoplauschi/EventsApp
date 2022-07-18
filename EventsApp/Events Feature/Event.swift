//
//  Event.swift
//  EventsApp
//
//  Created by Bogdan on 14.07.2022.
//

import Foundation

public struct Event: Equatable {
    public let name: String
    public let location: String
    public let dateInterval: String
    public let count: Int
    public let imageURL: URL?
    
    public init(name: String, location: String, dateInterval: String, count: Int, imageURL: URL?) {
        self.name = name
        self.location = location
        self.dateInterval = dateInterval
        self.count = count
        self.imageURL = imageURL
    }
}
