//
//  NetworkLoggerPlugin.swift
//  Hint
//
//  Created by Denys Telezhkin on 20.01.16.
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
import Alamofire

/**
 Plugin, that can be used to log network success and failure responses.
 */
open class NetworkLoggerPlugin : Plugin {
    
    /// Log successful requests
    open var logSuccess = false
    
    /// Log unsuccessful requests
    open var logFailures = true
    
    public init() {}
    
    open func willSendRequest<Model, ErrorModel>(_ request: BaseRequest<Model, ErrorModel>) {
        
    }
    
    open func willSendAlamofireRequest<Model, ErrorModel>(_ request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {
        
    }
    
    open func didSendAlamofireRequest<Model, ErrorModel>(_ request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {
        
    }
    
    open func didReceiveResponse<Model, ErrorModel>(response: (URLRequest?, HTTPURLResponse?, Data?, Error?), forRequest request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {
        if response.3 != nil {
            if logFailures {
                debugPrint("Request failed: \(request.debugDescription)")
            }
        } else {
            if logSuccess {
                debugPrint("Request success: \(request.debugDescription)")
            }
        }
    }
}
