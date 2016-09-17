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
public protocol JSONDecodable : Parseable  {
    
    /// Create model object from SwiftyJSON.JSON struct.
    init(json: JSON) throws
}

public extension JSONDecodable {
    static func parse<T:Parseable>(_ data: Data) throws -> T {
        guard let type = T.self as? JSONDecodable.Type else {
            throw ParsingError.wrongType
        }
        guard let model =  try type.init(json: JSON(data: data)) as? T else {
            throw ParsingError.constructionFailed
        }
        return model
    }
}

extension JSON : JSONDecodable {
    public init(json: JSON) throws {
        if let array = json.array { self.init(array) }
        else if let dictionary = json.dictionary { self.init(dictionary) }
        else { self.init(json.rawValue) }
    }
}

//extension Array : JSONDecodable {
//    public init(json: JSON) {
//        self.init(json.arrayValue.flatMap {
//            if let type = Element.self as? JSONDecodable.Type {
//                let element : Element?
//                do {
//                    element = try type.init(json: $0) as? Element
//                } catch {
//                    return nil
//                }
//                return element
//            }
//            return nil
//        })
//    }
//}

extension String : JSONDecodable  {
    public init(json: JSON) {
        self.init(json.stringValue)!
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
