//
//  ResponseBuilder.swift
//  Hint
//
//  Created by Denys Telezhkin on 11.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import Foundation
import SwiftyJSON

public class ResponseBuilder<T:JSONDecodable>
{
    func buildResponseFromJSON(json : JSON) -> T {
        return T(json: json)
    }
}