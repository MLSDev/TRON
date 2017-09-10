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
        } else {
            print("Failed to build model from \(fileName) in \(bundle)")
        }
    }
}

/// Error, that will be thrown if model creation failed while stubbing network request.
public struct APIStubConstructionError : Error {}

/**
 `APIStub` instance that is used to represent stubbed successful or unsuccessful response value.
 */
open class APIStub<Model, ErrorModel> {
    
    /// Should the stub be successful. By default - true
    open var successful = true
    
    /// Data to be passed to successful stub
    open var successData : Data?
    
    open var successDownloadURL : URL?
    
    /// Error to be passed into request's `errorParser` if stub is failureful.
    open var errorRequest : URLRequest?
    
    /// HTTP response to be passed into request's `errorParser` if stub is failureful.
    open var errorResponse: HTTPURLResponse?
    
    /// Error Data to be passed into request's `errorParser` if stub is failureful.
    open var errorData : Data?
    
    /// Loading error to be passed into request's `errorParser` if stub is failureful.
    open var loadingError : Error?
    
    /// Response model closure for successful API stub
    open var modelClosure : (() -> Model?)!
    
    /// Error model closure for unsuccessful API stub
    open var errorClosure: () -> APIError<ErrorModel> = { APIError(request: nil, response: nil, data: nil, error: nil) }
    
    /// Delay before stub is executed
    open var stubDelay = 0.1
    
    /// Creates `APIStub`, and configures it for `request`.
    public init(request: BaseRequest<Model,ErrorModel>) {
        if let request = request as? APIRequest<Model,ErrorModel>{
            let serializer = request.responseParser
            let errorSerializer = request.errorParser
            modelClosure = { [unowned self] in
                return serializer(nil,nil,self.successData,nil).value
            }
            errorClosure = { [unowned self] in
                return errorSerializer(nil, self.errorRequest, self.errorResponse, self.errorData, self.loadingError)
            }
        } else if let request = request as? UploadAPIRequest<Model,ErrorModel> {
            let serializer = request.responseParser
            let errorSerializer = request.errorParser
            modelClosure = { [unowned self] in
                return serializer(nil,nil,self.successData,nil).value
            }
            errorClosure = { [unowned self] in
                return errorSerializer(nil, self.errorRequest, self.errorResponse, self.errorData, self.loadingError)
            }
        } else if let request = request as? DownloadAPIRequest<Model,ErrorModel> {
            let serializer = request.responseParser
            let errorSerializer = request.errorParser
            modelClosure = { [unowned self] in
                return serializer(nil,nil,self.successDownloadURL,nil).value
            }
            errorClosure = { [unowned self] in
                return errorSerializer(nil, self.errorRequest, self.errorResponse, nil, self.loadingError)
            }
        } else {
            modelClosure = { return nil }
        }
    }
    
    /**
     Stub current request.
     
     - parameter successBlock: Success block to be executed when request finished
     
     - parameter failureBlock: Failure block to be executed if request fails. Nil by default.
     */
    open func performStub(withSuccess successBlock: ((Model) -> Void)? = nil, failure failureBlock: ((APIError<ErrorModel>) -> Void)? = nil) {
        performStub { (dataResponse:DataResponse<Model>) -> Void in
            switch dataResponse.result {
            case .success(let model):
                successBlock?(model)
            case .failure(let error):
                if let error = error as? APIError<ErrorModel> {
                    failureBlock?(error)
                } else {
                    failureBlock?(APIError(request: nil, response:nil,data: nil, error: error))
                }
            }
        }
    }
    
    /**
     Stub current request.
     
     - parameter completionBlock: Completion block to be executed when request is stubbed.
     */
    open func performStub(withCompletion completionBlock : @escaping ((Alamofire.DataResponse<Model>) -> Void)) {
        delay(stubDelay) {
            let result : Alamofire.Result<Model>
            if self.successful {
                if let model = self.modelClosure?() {
                    result = Result.success(model)
                } else {
                    result = Result.failure(APIStubConstructionError())
                }
            } else {
                result = Result.failure(self.errorClosure())
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
        delay(stubDelay) {
            let result : Alamofire.Result<Model>
            if self.successful {
                if let model = self.modelClosure?() {
                    result = Result.success(model)
                } else {
                   result = .failure(APIStubConstructionError())
                }
            } else {
                result = Result.failure(self.errorClosure())
            }
            let response: DownloadResponse<Model> = DownloadResponse(request: nil, response: nil, temporaryURL: nil, destinationURL: nil, resumeData: nil, result: result)
            completionBlock(response)
        }
    }
}
