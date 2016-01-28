//
//  HeaderBuilder.swift
//  Hint
//
//  Created by Denys Telezhkin on 11.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import Foundation

class JSONHeaderBuilder : HeaderBuildable {
    func headersForAuthorization(requirement: AuthorizationRequirement, headers: [String : String]) -> [String : String] {
        return ["Accept":"application/json"]
    }
}