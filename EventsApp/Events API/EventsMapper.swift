//
//  EventsMapper.swift
//  EventsApp
//
//  Created by Bogdan on 19.07.2022.
//

import Foundation

final class EventsMapper {
    private static let jsonDecoder = JSONDecoder()
    
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [VividSeatsAPIEvent] {
        guard response.isSuccessful, let root = try? jsonDecoder.decode([VividSeatsAPIEvent].self, from: data) else {
            throw VividSeatsAPIEventsLoader.Error.invalidData
        }
        
        return root
    }
}
