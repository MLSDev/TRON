//
//  MultipartAPIRequest.swift
//  Hint
//
//  Created by Denys Telezhkin on 15.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import UIKit
import Alamofire

typealias ProgressClosure = (bytesSent: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void

class MultipartAPIRequest<Model: JSONDecodable, ErrorModel: JSONDecodable>: APIRequest<Model, ErrorModel> {
    
    private var multipartParameters: [MultipartFormData -> Void] = []
    
    override init(path: String) {
        super.init(path: path)
    }
    
    @available(*, unavailable, message="MultipartAPIRequest should use performWithSuccess(_:failure:progress:cancellableCallback:)")
    override func performWithSuccess(success: Model -> Void, failure: (APIError<ErrorModel> -> Void)?) -> Cancellable {
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
    
    func performWithSuccess(success: Model -> Void, failure: APIError<ErrorModel> -> Void, progress: ProgressClosure, cancellableCallback: Cancellable -> Void)
    {
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
        
        let encodingCompletion: Manager.MultipartFormDataEncodingResult -> Void = { completion in
            if case .Failure(let error) = completion {
                let apiError = APIError<ErrorModel>(request: nil, response: nil, data: nil, error: error as NSError)
                failure(apiError)
            } else if case .Success(let request, _, _) = completion {
                request.progress(progress).validate().handleResponse(success, failure: failure, responseBuilder: self.responseBuilder, errorBuilder: self.errorBuilder, plugins: self.allPlugins)
                cancellableCallback(request)
            }
        }
        
        Alamofire.upload(method, urlBuilder.urlForPath(path),
            headers:  headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers),
            multipartFormData:  multipartConstructionBlock,
            encodingMemoryThreshold: Manager.MultipartFormDataEncodingMemoryThreshold,
            encodingCompletion:  encodingCompletion)
    }
}

