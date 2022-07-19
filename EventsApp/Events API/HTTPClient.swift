//
//  HTTPClient.swift
//  EventsApp
//
//  Created by Bogdan on 19.07.2022.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    
    func post(to url: URL, completion: @escaping (Result) -> Void)
}
