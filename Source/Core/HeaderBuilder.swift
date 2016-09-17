//
//  HeaderBuilder.swift
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
 `HeaderBuilder` class is used to construct HTTP headers for URLRequest.
 */
open class HeaderBuilder: HeaderBuildable {
    
    /// Default headers to be included in all requests
    open let defaultHeaders : [String:String]
    
    /**
     Initialize with defaultHeaders
     
     - parameter defaultHeaders: Default headers to be added.
     */
    public init(defaultHeaders: [String:String]) {
        self.defaultHeaders = defaultHeaders
    }
    
    /**
     Construct headers for specific request.
     
     - parameter requirement: Authorization requirement of current request
     
     - parameter headers : headers to be included in this specific request
     
     - returns: HTTP headers for current request
     */
    open func headers(forAuthorizationRequirement requirement: AuthorizationRequirement, including headers: [String : String]) -> [String : String] {
        var combinedHeaders = defaultHeaders
        headers.forEach {
            combinedHeaders[$0.0] = $0.1
        }
        return combinedHeaders
    }
}

