//
//  MultipartAPIRequest.swift
//  TRON
//
//  Created by Denys Telezhkin on 15.05.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
import Alamofire

public class MultipartAPIRequest<Model: ResponseParseable, ErrorModel: ResponseParseable>: BaseRequest<Model,ErrorModel>
{
    let multipartFormData : (MultipartFormData) -> Void
    
    /**
     Create MultipartAPIRequest for specified relative path.
     
     - parameter path: relative path
     
     - parameter tron: TRON instance to use for basic configuration
     
     - parameter multipartFormData: Multipart-form data creation block.
     */
    public init(path: String, tron: TRON, multipartFormData:(MultipartFormData) -> Void) {
        self.multipartFormData = multipartFormData
        super.init(path: path, tron: tron)
    }
    
    /**
     Perform multipart form data upload.
     
     - parameter success: Success block to be executed when request finished
     
     - parameter failure: Failure block to be executed if request fails. Nil by default.
     
     - parameter encodingMemoryThreshold: Memory threshold, depending on which request will be streamed from disk or from memory
     
     - parameter encodingCompletion: Encoding completion block, that can be used to inspect encoding result. No action is required by default, therefore default value for this block is nil.
     */
    public func performMultipart(success: (Model) -> Void, failure: ((APIError<ErrorModel>) -> Void)? = nil, encodingMemoryThreshold: UInt64 = Manager.MultipartFormDataEncodingMemoryThreshold, encodingCompletion: ((Manager.MultipartFormDataEncodingResult) -> Void)? = nil)
    {
        guard let manager = tronDelegate?.manager else {
            fatalError("Manager cannot be nil while performing APIRequest")
        }
        
        if stubbingEnabled {
            apiStub.performStubWithSuccess(success, failure: failure)
            return
        }
        
        let multipartConstructionBlock: (MultipartFormData) -> Void = { requestFormData in
            self.parameters.forEach { (key,value) in
                requestFormData.appendBodyPart(data: String(value).data(using:.utf8) ?? Data(), name: key)
            }
            self.multipartFormData(requestFormData)
        }
        
        let encodingCompletion: (Manager.MultipartFormDataEncodingResult) -> Void = { completion in
            if case .failure(let error) = completion {
                let apiError = APIError<ErrorModel>(request: nil, response: nil, data: nil, error: error as NSError)
                failure?(apiError)
            } else if case .success(let request, _, _) = completion {
                let allPlugins = self.plugins + (self.tronDelegate?.plugins ?? [])
                allPlugins.forEach {
                    $0.willSendRequest(request.request)
                }
                _ = request.validate().response(queue : self.processingQueue,
                                            responseSerializer: self.responseSerializer(notifyingPlugins:allPlugins))
                {
                    self.callSuccessFailureBlocks(success, failure: failure, response: $0)
                }
                if !(self.tronDelegate?.manager.startRequestsImmediately ?? false){
                    request.resume()
                }
                encodingCompletion?(completion)
            }
        }
        
        manager.upload(method, urlBuilder.urlForPath(path),
                       headers:  headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers),
                       multipartFormData:  multipartConstructionBlock,
                       encodingMemoryThreshold: encodingMemoryThreshold,
                       encodingCompletion:  encodingCompletion)
    }
}
