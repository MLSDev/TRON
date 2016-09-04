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

private func delay(_ delay:Double, closure:@escaping ()->Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: closure)
}

public extension APIStub {
    /**
     Build stub model from file in specified bundle
     
     - parameter fileName: Name of the file to build response from
     - parameter bundle: bundle to look for file.
     */
    public func buildModel(fromFileNamed fileName: String, inBundle bundle: Bundle = Bundle.main) {
        if let filePath = bundle.path(forResource: fileName as String, ofType: nil)
        {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
                    print("failed building response model from file: \(filePath)")
                return
            }
            model = try? Model.parse(data)
        }
    }
}

/**
 `APIStub` instance that is used to represent stubbed successful or unsuccessful response value.
 */
open class APIStub<Model: Parseable, ErrorModel: Parseable> {
    
    /// Should the stub be successful. By default - true
    open var successful = true
    
    /// Response model for successful API stub
    open var model : Model?
    
    /// Error model for unsuccessful API stub
    open var error: APIError<ErrorModel>?
    
    /// Delay before stub is executed
    open var stubDelay = 0.1
    
    /**
     Stub current request.
     
     - parameter success: Success block to be executed when request finished
     
     - parameter failure: Failure block to be executed if request fails. Nil by default.
     */
    open func performStub(withSuccess successBlock: ((Model) -> Void)? = nil, failure failureBlock: ((APIError<ErrorModel>) -> Void)? = nil) {
        if let model = model, successful {
            delay(stubDelay) {
                successBlock?(model)
            }
        } else if let error = error {
            delay(stubDelay) {
                failureBlock?(error)
            }
        }
    }
    
    /**
     Stub current request.
     
     - parameter completion: Completion block to be executed when request is stubbed.
     */
    open func performStub(withCompletion completionBlock : ((Alamofire.Response<Model>) -> Void)) {
        delay(stubDelay) {
            let result : Alamofire.Result<Model>
            if let model = self.model, self.successful {
                result = Result.success(model)
            } else if let error = self.error {
                result = Result.failure(error)
            } else {
                let error : APIError<ErrorModel> = APIError(request: nil, response: nil, data: nil, error: nil)
                result = Result.failure(error)
            }
            let response: Alamofire.Response<Model> = Alamofire.Response(request: nil, response: nil, data: nil, result: result)
            completionBlock(response)
        }
    }
}

// DEPRECATED

extension APIStub {
    @available(*,unavailable,renamed:"buildModel(fromFileNamed:inBundle:)")
    public func buildModelFromFile(_ fileName: String, inBundle bundle: Bundle = Bundle.main) {
        fatalError("UNAVAILABLE")
    }
    
    @available(*,unavailable,renamed:"performStub(withSuccess:failure:)")
    open func performStubWithSuccess(_ success: ((Model) -> Void)? = nil, failure: ((APIError<ErrorModel>) -> Void)? = nil) {
        fatalError("UNAVAILABLE")
    }
    
    @available(*,unavailable,renamed:"performStub(withCompletion:)")
    open func performStubWithCompletion(_ completion : ((Alamofire.Response<Model>) -> Void)) {
        fatalError("UNAVAILABLE")
    }
}
