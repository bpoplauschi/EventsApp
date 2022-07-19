//
//  HTTPURLResponse+StatusCode.swift
//  EventsApp
//
//  Created by Bogdan on 19.07.2022.
//

import Foundation

extension HTTPURLResponse {
    private static var SUCCESS_200: Int { 200 }
    
    var isSuccessful: Bool { statusCode == HTTPURLResponse.SUCCESS_200 }
}
