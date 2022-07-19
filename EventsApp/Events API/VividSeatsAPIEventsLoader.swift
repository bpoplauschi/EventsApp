//
//  VividSeatsAPIEventsLoader.swift
//  EventsApp
//
//  Created by Bogdan on 19.07.2022.
//

import Foundation

public final class VividSeatsAPIEventsLoader: EventsLoader {
    private let url: URL
    private let httpClient: HTTPClient
    
    public typealias Result = EventsLoader.Result
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(url: URL, httpClient: HTTPClient) {
        self.url = url
        self.httpClient = httpClient
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        httpClient.post(to: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success((data, response)):
                completion(VividSeatsAPIEventsLoader.map(data, from: response))
                
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
    
    private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            let events = try EventsMapper.map(data, from: response)
            return .success(events.toModels())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == VividSeatsAPIEvent {
    func toModels() -> [Event] {
        map { Event(
            name: $0.topLabel,
            location: $0.middleLabel,
            dateInterval: $0.bottomLabel,
            count: $0.eventCount,
            imageURL: URL(string: $0.image))
        }
    }
}
