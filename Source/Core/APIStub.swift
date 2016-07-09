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
import Alamofire

private func delay(_ delay:Double, closure:()->()) {
    DispatchQueue.main.after(
        when: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
        execute: closure)
}

public extension APIStub {
    /**
     Build stub model from file in specified bundle
     
     - parameter fileName: Name of the file to build response from
     - parameter bundle: bundle to look for file.
     */
    public func buildModelFromFile(_ fileName: String, inBundle bundle: Bundle = Bundle.main) {
        if let filePath = bundle.pathForResource(fileName as String, ofType: nil)
        {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
                    print("failed building response model from file: \(filePath)")
                return
            }
            model = try? Model(data: data)
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
    public var model : Model?
    
    /// Error model for unsuccessful API stub
    public var error: APIError<ErrorModel>?
    
    /// Delay before stub is executed
    public var stubDelay = 0.1
    
    /**
     Stub current request.
     
     - parameter success: Success block to be executed when request finished
     
     - parameter failure: Failure block to be executed if request fails. Nil by default.
     */
    public func performStubWithSuccess(_ success: (Model) -> Void, failure: ((APIError<ErrorModel>) -> Void)? = nil) {
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
    
    /**
     Stub current request.
     
     - parameter completion: Completion block to be executed when request is stubbed.
     */
    public func performStubWithCompletion(_ completion : ((Alamofire.Response<Model,APIError<ErrorModel>>) -> Void)) {
        delay(stubDelay) {
            let result : Alamofire.Result<Model,APIError<ErrorModel>>
            if let model = self.model where self.successful {
                result = Result.success(model)
            } else if let error = self.error {
                result = Result.failure(error)
            } else {
                let error : APIError<ErrorModel> = APIError(request: nil, response: nil, data: nil, error: nil)
                result = Result.failure(error)
            }
            let response: Alamofire.Response<Model, APIError<ErrorModel>> = Alamofire.Response(request: nil, response: nil, data: nil, result: result)
            completion(response)
        }
    }
}
