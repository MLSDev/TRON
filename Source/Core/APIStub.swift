//
//  APIStub.swift
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

private func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

public extension APIStub {
    /**
     Build stub model from file in specified bundle
     
     - parameter fileName: Name of the file to build response from
     - parameter bundle: bundle to look for file.
     */
    public func buildModelFromFile(fileName: String, inBundle bundle: NSBundle = NSBundle.mainBundle()) {
        if let filePath = bundle.pathForResource(fileName as String, ofType: nil)
        {
            guard let data = NSData(contentsOfFile: filePath),
                let json = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) else {
                    print("failed building response model from file: \(filePath)")
                return
            }
            model = try? Model.from(json)
        }
    }
}

/**
 `APIStub` instance that is used to represent stubbed successful or unsuccessful response value.
 */
public class APIStub<Model: ResponseParseable, ErrorModel: ResponseParseable> {
    
    /// Should the stub be successful. By default - true
    public var successful = true
    
    /// Response model for successful API stub
    public var model : Model.ModelType?
    
    /// Error model for unsuccessful API stub
    public var error: APIError<ErrorModel>?
    
    /// Delay before stub is executed
    public var stubDelay = 0.1
    
    public var description: String {
        return "\(self.dynamicType): \n Successful: \(successful) \n Model: \(model) \n Error: \(error)"
    }
    
    public var debugDescription : String {
        return description
    }
    
    public func cancel() {
        
    }
    
    /**
     Stub current request.
     
     - parameter success: Success block to be executed when request finished
     
     - parameter failure: Failure block to be executed if request fails. Nil by default.
     
     - returns: Request token. Can not be cancelled.
     */
    public func performStubWithSuccess(success: Model.ModelType -> Void, failure: (APIError<ErrorModel> -> Void)? = nil) {
        if let model = model where successful {
            delay(stubDelay) {
                success(model)
            }
        } else if let error = error {
            delay(stubDelay) {
                failure?(error)
            }
        }
    }
}