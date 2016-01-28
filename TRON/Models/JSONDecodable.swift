//
//  JSONDecodable.swift
//  Hint
//
//  Created by Anton Golikov on 08.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import SwiftyJSON

public protocol JSONDecodable {
    init(json: JSON)
}

extension JSON : JSONDecodable {
    public init(json: JSON) {
        if let array = json.array { self.init(array) }
        else if let dictionary = json.dictionary { self.init(dictionary) }
        else { self.init(json.rawValue) }
    }
}
extension Array : JSONDecodable {
    public init(json: JSON) {
        self.init(json.arrayValue.flatMap {
            if let type = Element.self as? JSONDecodable.Type {
                return type.init(json: $0) as? Element
            }
            return nil
        })
    }
}

extension String : JSONDecodable  {
    public init(json: JSON) {
        self.init(json.stringValue)
    }
}
extension Int : JSONDecodable  {
    public init(json: JSON) {
        self.init(json.intValue)
    }
}
extension Float : JSONDecodable {
    public init(json: JSON) {
        self.init(json.floatValue)
    }
}
extension Double : JSONDecodable {
    public init(json: JSON) {
        self.init(json.doubleValue)
    }
}
extension Bool : JSONDecodable {
    public init(json: JSON) {
        self.init(json.boolValue)
    }
}