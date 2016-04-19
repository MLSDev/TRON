//
//  ResponseBuilder.swift
//  Hint
//
//  Created by Denys Telezhkin on 11.12.15.
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

/// Generic parsing protocol, used as generic constraint in `APIRequest`. It can be adopted to be used with various mappers. For example, JSONDecodable protocol demonstrates `ResponseParseable` protocol usage with SwiftyJSON mapper.
public protocol ResponseParseable {
    
    /// Type of response
    associatedtype ModelType = Self
    
    /**
     Parse response from the server into concrete instance
     
     - parameter json: JSON object
     - returns: parsed model
     - note: Ideally, we would like to return Self here, however Swift 2 understands Self as final class or struct and therefore prohibits subclassing. Which is why we are using workaround with ModelType.
     */
    static func from(json: AnyObject) throws -> ModelType
}

/**
 Default ResponseBuilder.
 */
public class ResponseBuilder<T:ResponseParseable>
{
    /// Initialize default response builder
    public init() {}
//    
//    /**
//     Create model from json response.
//     
//     - parameter json: AnyObject instance
//     
//     - returns parsed model.
//     */
    public func buildResponseFromJSON(json : AnyObject) throws -> T.ModelType {
        return try T.from(json)
    }
}

