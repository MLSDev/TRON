//
//  SwiftyJSONBuilder.swift
//  TRON
//
//  Created by Denys Telezhkin on 06.02.16.
//  Copyright © 2015 - present MLSDev. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import SwiftyJSON

/**
 Protocol for parsing JSON response. It is used as a generic constraint for `APIRequest` instance.
 */
public protocol JSONDecodable  : ResponseParseable {
    
    /// Create model object from SwiftyJSON.JSON struct.
    init(json: JSON)
}

public extension ResponseParseable where Self.ModelType : JSONDecodable, Self == Self.ModelType {
    public static func from(json: AnyObject) throws -> ModelType {
        return self.init(json: JSON(json))
    }
}

extension JSON : JSONDecodable {
    public init(json: JSON) {
        if let array = json.array { self.init(array) }
        else if let dictionary = json.dictionary { self.init(dictionary) }
        else { self.init(json.rawValue) }
    }
}
//
//public struct CollectionTypeError : ErrorType {}
//
//public extension CollectionType where Generator.Element: ResponseParseable,  Generator.Element == Generator.Element.ModelType {
//    static func from(json: AnyObject) throws -> [Generator.Element] {
//        guard let array = json as? [AnyObject] else {
//            throw CollectionTypeError()
//        }
//        return array.flatMap { return try? Generator.Element.from($0) }
//    }
//}
//
//extension JSONDecodable where Self: CollectionType, Self.Generator.Element : JSONDecodable, Self.Generator.Element == Self.Generator.Element.ModelType {
//    init(json: JSON) {
//        let foo = json.arrayValue.flatMap({
//            return Self.Generator.Element.init(json: $0)
//        })
//        
//    }
//}

//extension Array : JSONDecodable {
//    public init(json: JSON) {
//        self.init(json.arrayValue.flatMap {
//            if let type = Element.self as? JSONDecodable.ModelType {
//                return type.init(json: $0) as? Element
//            }
//            return nil
//        })
//    }
//}

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