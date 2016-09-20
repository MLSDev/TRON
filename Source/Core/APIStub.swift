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
            successData = try? Data(contentsOf: URL(fileURLWithPath: filePath))
        }
    }
}

/**
 `APIStub` instance that is used to represent stubbed successful or unsuccessful response value.
 */
open class APIStub<Model, ErrorModel> {
    
    /// Should the stub be successful. By default - true
    open var successful = true
    
    /// Data to be passed to successful stub
    open var successData : Data?
    
    /// Error to be passed into request's `errorParser` if stub is failureful.
    open var errorRequest : URLRequest?
    
    /// HTTP response to be passed into request's `errorParser` if stub is failureful.
    open var errorResponse: HTTPURLResponse?
    
    /// Error Data to be passed into request's `errorParser` if stub is failureful.
    open var errorData : Data?
    
    /// Loading error to be passed into request's `errorParser` if stub is failureful.
    open var loadingError : Error?
    
    /// Response model for successful API stub
    open var model : Model? {
        guard let data = successData else { return nil }
        guard let request = request else { return nil}
        return try? request.responseParser(data)
    }
    
    /// Error model for unsuccessful API stub
    open var error: APIError<ErrorModel>? {
        return request?.errorParser(errorRequest, errorResponse, errorData, loadingError)
    }
    
    /// Delay before stub is executed
    open var stubDelay = 0.1
    
    /// Weak request property, that is used when executing stubs using request `errorParser` or `responseParser`.
    open weak var request: BaseRequest<Model,ErrorModel>?
    
    /// Creates `APIStub`, and configures it for `request`.
    init(request: BaseRequest<Model,ErrorModel>) {
        self.request = request
    }
    
    /**
     Stub current request.
     
     - parameter successBlock: Success block to be executed when request finished
     
     - parameter failureBlock: Failure block to be executed if request fails. Nil by default.
     */
    open func performStub(withSuccess successBlock: ((Model) -> Void)? = nil, failure failureBlock: ((APIError<ErrorModel>) -> Void)? = nil) {
        delay(stubDelay) { [weak self] in
            if self?.successful ?? false {
                guard let model = self?.model else {
                    print("Attempting to stub successful request, however successData is nil")
                    return
                }
                successBlock?(model)
            } else {
                guard let error = self?.error else {
                    print("Attempting to stub failed request, however apiStub does not produce error")
                    return
                }
                failureBlock?(error)
            }
        }
    }
    
    /**
     Stub current request.
     
     - parameter completionBlock: Completion block to be executed when request is stubbed.
     */
    open func performStub(withCompletion completionBlock : @escaping ((Alamofire.DataResponse<Model>) -> Void)) {
        delay(stubDelay) { [weak self] in
            let result : Alamofire.Result<Model>
            if self?.successful ?? false {
                guard let model = self?.model else {
                    print("Attempting to stub successful request, however successData is nil")
                    return
                }
                result = Result.success(model)
            } else {
                guard let error = self?.error else {
                    print("Attempting to stub failed request, however apiStub does not produce error")
                    return
                }
                result = Result.failure(error)
            }
            let response: Alamofire.DataResponse<Model> = Alamofire.DataResponse(request: nil, response: nil, data: nil, result: result)
            completionBlock(response)
        }
    }
    
    /**
     Stub current download request.
     
     - parameter completionBlock: Completion block to be executed when request is stubbed.
     */
    open func performStub(withCompletion completionBlock : @escaping ((Alamofire.DownloadResponse<Model>) -> Void)) {
        delay(stubDelay) { [weak self] in
            let result : Alamofire.Result<Model>
            if self?.successful ?? false {
                guard let model = self?.model else {
                    print("Attempting to stub successful download request, however successData is nil")
                    return
                }
                result = Result.success(model)
            } else {
                guard let error = self?.error else {
                    print("Attempting to stub failed download request, however apiStub does not produce error")
                    return
                }
                result = Result.failure(error)
            }
            let response: DownloadResponse<Model> = DownloadResponse(request: nil, response: nil, temporaryURL: nil, destinationURL: nil, resumeData: nil, result: result)
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
    open func performStubWithCompletion(_ completion : ((Alamofire.DataResponse<Model>) -> Void)) {
        fatalError("UNAVAILABLE")
    }
}
