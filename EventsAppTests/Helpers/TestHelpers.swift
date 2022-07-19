//
//  TestHelpers.swift
//  EventsAppTests
//
//  Created by Bogdan on 19.07.2022.
//

import Foundation

func anyData() -> Data { Data("any data".utf8) }
func anyNSError() -> NSError { NSError(domain: "any error", code: 0) }
func anyURL() -> URL { URL(string: "http://any-url")! }
