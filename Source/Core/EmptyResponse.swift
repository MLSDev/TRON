//
//  EmptyResponse.swift
//  TRON
//
//  Created by Denys Telezhkin on 25.03.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation

public struct EmptyResponse : ResponseParseable {
    
    public init() {}
    
    public static func from(json: AnyObject) throws -> EmptyResponse {
        return EmptyResponse()
    }
}