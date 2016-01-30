//
//  ErrorBuilder.swift
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
import SwiftyJSON

public class ErrorBuilder<U:JSONDecodable>
{
    func buildErrorFromRequest(request : NSURLRequest?, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> APIError<U> {
        return APIError<U>(request: request, response: response, data: data, error: error)
    }
}

public struct APIError<T:JSONDecodable> {
    public let request : NSURLRequest?
    public let response : NSHTTPURLResponse?
    public let data : NSData?
    public let error : NSError?
    public var errorModel : T?
    
    public init(request : NSURLRequest?, response: NSHTTPURLResponse?, data: NSData?, error: NSError?)
    {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
        self.errorModel = data != nil ? T(json: JSON(data: data!)) : nil
    }
    
    public init(errorModel: T) {
        self.init(request: nil, response: nil, data: nil, error: nil)
        self.errorModel = errorModel
    }
}

