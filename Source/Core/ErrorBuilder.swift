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

/**
 `ErrorBuilder` class is used to build error object from unsuccessful API requests.
 */
public class ErrorBuilder<U:ResponseParseable>
{
    /// initialize default error builder
    public init() {}
    
    /**
     Build concrete APIError instance.
     
     - parameter request: NSURLRequest that was unsuccessful
     
     - parameter response: response received from web service
     
     - parameter data: data, contained in response
     
     - error: Error instance, created by Foundation Loading System or Alamofire.
     
     - returns APIError instance
     */
    public func buildErrorFromRequest(_ request : URLRequest?, response: HTTPURLResponse?, data: Data?, error: NSError?) -> APIError<U> {
        return APIError<U>(request: request, response: response, data: data, error: error)
    }
}

/// `APIError<T>` is used as a generic wrapper for all kinds of APIErrors.
public struct APIError<T:ResponseParseable> : ErrorProtocol {
    
    /// NSURLRequest that was unsuccessful
    public let request : URLRequest?
    
    /// Response received from web service
    public let response : HTTPURLResponse?
    
    /// Data, contained in response
    public let data : Data?
    
    /// Error instance, created by Foundation Loading System or Alamofire.
    public let error : NSError?
    
    /// Parsed Error model
    public var errorModel : T?
    
    /**
     Initialize `APIError` with unsuccessful request info.
     
     - parameter request: NSURLRequest that was unsuccessful
     
     - parameter response: response received from web service
     
     - parameter data: data, contained in response
     
     - error: Error instance, created by Foundation Loading System or Alamofire.
     */
    public init(request : URLRequest?, response: HTTPURLResponse?, data: Data?, error: NSError?)
    {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
//        guard let object = try? data?.parseToAnyObject() else {
//            return
//        }
        self.errorModel = try? T(data: data ?? Data())
    }
    
    /**
     Convenience initializer, that can be used to create fixtured `APIError`.
     */
    public init(errorModel: T) {
        self.init(request: nil, response: nil, data: nil, error: nil)
        self.errorModel = errorModel
    }
}

