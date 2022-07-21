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
    private let jsonEncoder: JSONEncoder
    
    public typealias Result = EventsLoader.Result
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidResponseData
        case invalidRequestData
    }
    
    public init(url: URL, httpClient: HTTPClient, jsonEncoder: JSONEncoder = JSONEncoder()) {
        self.url = url
        self.httpClient = httpClient
        self.jsonEncoder = jsonEncoder
    }
    
    public func load(startDate: Date, endDate: Date, completion: @escaping (Result) -> Void) {
        guard let params = try? jsonEncoder.encode(LoadEventsRequest(startDate: startDate, endDate: endDate)) else {
            completion(.failure(Error.invalidRequestData))
            return
        }
        
        httpClient.post(to: url, body: params) { [weak self] result in
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

private struct LoadEventsRequest: Encodable {
    let startDate: String
    let endDate: String
    let includeSuggested: String
    
    init(startDate: Date, endDate: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.startDate = dateFormatter.string(from: startDate)
        self.endDate = dateFormatter.string(from: endDate)
        self.includeSuggested = "true"
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
