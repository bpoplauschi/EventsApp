//
//  EventsLoader.swift
//  EventsApp
//
//  Created by Bogdan on 14.07.2022.
//

import Foundation

public protocol EventsLoader {
    typealias Result = Swift.Result<[Event], Error>
    
    func load(completion: @escaping (Result) -> Void)
}
