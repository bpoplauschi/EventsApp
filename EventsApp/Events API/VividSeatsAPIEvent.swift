//
//  VividSeatsAPIEvent.swift
//  EventsApp
//
//  Created by Bogdan on 19.07.2022.
//

struct VividSeatsAPIEvent: Decodable {
    let topLabel: String
    let middleLabel: String
    let bottomLabel: String
    let eventCount: Int
    let image: String
    let targetId: Int
    let targetType: String
    let entityId: Int
    let entityType: String
    let startDate: Int64
    let rank: Int
}
