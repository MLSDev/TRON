//
//  MultipartAPIRequest.swift
//  Hint
//
//  Created by Denys Telezhkin on 15.12.15.
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

import UIKit
import Alamofire

typealias ProgressClosure = (bytesSent: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void

class MultipartAPIRequest<Model: JSONDecodable, ErrorModel: JSONDecodable>: APIRequest<Model, ErrorModel> {
    
    private var multipartParameters: [MultipartFormData -> Void] = []
    
    override init(path: String, tron: TRON) {
        super.init(path: path, tron: tron)
    }
    
    @available(*, unavailable, message="MultipartAPIRequest should use performWithSuccess(_:failure:progress:cancellableCallback:)")
    override func performWithSuccess(success: Model -> Void, failure: (APIError<ErrorModel> -> Void)?) -> RequestToken {
        fatalError()
    }
    
    func appendMultipartData(data: NSData, name: String, filename: String? = nil, mimeType: String? = nil) {
        multipartParameters.append { formData in
            if let filename = filename, let mimeType = mimeType {
                formData.appendBodyPart(data: data, name: name, fileName: filename, mimeType: mimeType)
            } else if let mimeType = mimeType {
                formData.appendBodyPart(data: data, name: name, mimeType: mimeType)
            } else {
                formData.appendBodyPart(data: data, name: name)
            }
        }
    }
    
    func performWithSuccess(success: Model -> Void, failure: (APIError<ErrorModel> -> Void)? = nil, progress: ProgressClosure, cancellableCallback: RequestToken -> Void)
    {
        guard let manager = tronDelegate?.manager else {
            fatalError("Manager cannot be nil while performing APIRequest")
        }
        
        if stubbingEnabled {
            apiStub.performStubWithSuccess(success, failure: failure)
            return
        }
        
        let multipartConstructionBlock: MultipartFormData -> Void = { formData in
            self.parameters.forEach { (key,value) in
                formData.appendBodyPart(data: value.dataUsingEncoding(NSUTF8StringEncoding) ?? NSData(), name: key)
            }
            self.multipartParameters.forEach { $0(formData) }
        }
        
        let encodingCompletion: Manager.MultipartFormDataEncodingResult -> Void = { [unowned self] completion in
            if case .Failure(let error) = completion {
                let apiError = APIError<ErrorModel>(request: nil, response: nil, data: nil, error: error as NSError)
                failure?(apiError)
            } else if case .Success(let request, _, _) = completion {
                let allPlugins = self.plugins + (self.tronDelegate?.plugins ?? [])
                request.progress(progress).validate().handleResponse(success, failure: failure, responseBuilder: self.responseBuilder, errorBuilder: self.errorBuilder, plugins: allPlugins)
                cancellableCallback(request)
            }
        }
        
        manager.upload(method, urlBuilder.urlForPath(path),
            headers:  headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers),
            multipartFormData:  multipartConstructionBlock,
            encodingMemoryThreshold: Manager.MultipartFormDataEncodingMemoryThreshold,
            encodingCompletion:  encodingCompletion)
    }
}

