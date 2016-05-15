//
//  APIRequest.swift
//  Hint
//
//  Created by Anton Golikov on 08.12.15.
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

import Alamofire

/// Enum for various request types.
public enum RequestType {
    /// Will create `NSURLSessionDataTask`
    case Default
    
    /// Will create `NSURLSessionUploadTask` using `uploadTaskWithRequest(_:fromFile:)` method
    case UploadFromFile(NSURL)
    
    /// Will create `NSURLSessionUploadTask` using `uploadTaskWithRequest(_:fromData:)` method
    case UploadData(NSData)
    
    /// Will create `NSURLSessionUploadTask` using `uploadTaskWithStreamedRequest(_)` method
    case UploadStream(NSInputStream)
    
    /// Will create `NSURLSessionDownloadTask` using `downloadTaskWithRequest(_)` method
    case Download(Request.DownloadFileDestination)
    
    /// Will create `NSURLSessionDownloadTask` using `downloadTaskWithResumeData(_)` method
    case DownloadResuming(data: NSData, destination: Request.DownloadFileDestination)
}

/**
 `APIRequest` encapsulates request creation logic, stubbing options, and response/error parsing. It is reusable and configurable for any needs.
 */
public class APIRequest<Model: ResponseParseable, ErrorModel: ResponseParseable>: BaseRequest<Model,ErrorModel> {
    
    internal let requestType: RequestType
    
    internal func alamofireRequest(from manager: Alamofire.Manager) -> Alamofire.Request {
        switch requestType {
        case .Default:
            return manager.request(method, urlBuilder.urlForPath(path),
                                   parameters: parameters,
                                   encoding: encoding,
                                   headers:  headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers))
            
        case .UploadFromFile(let url):
            return manager.upload(method, urlBuilder.urlForPath(path),
                                  headers: headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers),
                                  file: url)
        
        case .UploadData(let data):
            return manager.upload(method, urlBuilder.urlForPath(path),
                                  headers: headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers),
                                  data: data)
            
        case .UploadStream(let stream):
            return manager.upload(method, urlBuilder.urlForPath(path),
                                  headers: headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers),
                                  stream: stream)
            
        case .Download(let destination):
            return manager.download(method, urlBuilder.urlForPath(path),
                                    parameters: parameters,
                                    encoding: encoding,
                                    headers: headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers),
                                    destination: destination)
        
        case .DownloadResuming(let data, let destination):
            return manager.download(data, destination: destination)
        }
    }
    
    /**
    Initialize request with relative path and `TRON` instance.
     
     - parameter path: relative path to resource.
     
     - parameter tron: `TRON` instance to be used to configure current request.
     */
    public init(type: RequestType, path: String, tron: TRON) {
        self.requestType = type
        super.init(path: path, tron: tron)
    }
    
    @available(*, deprecated, renamed="perform")
    public func performWithSuccess(success: Model.ModelType -> Void, failure: (APIError<ErrorModel> -> Void)? = nil) -> Alamofire.Request?
    {
        return perform(success: success, failure: failure)
    }
    
    /**
     Send current request.
     
     - parameter success: Success block to be executed when request finished
     
     - parameter failure: Failure block to be executed if request fails. Nil by default.
     
     - returns: Alamofire.Request or nil if request was stubbed.
     */
    public func perform(success success: Model.ModelType -> Void, failure: (APIError<ErrorModel> -> Void)? = nil) -> Alamofire.Request?
    {
        if stubbingEnabled {
            apiStub.performStubWithSuccess(success, failure: failure)
            return nil
        }
        return performAlamofireRequest(success, failure: failure)
    }
    
    /**
     Perform current request with completion block, that contains Alamofire.Response.
     
     - parameter completion: Alamofire.Response completion block.
     
     - returns: Alamofire.Request or nil if request was stubbed.
    */
    public func perform(completion completion: (Alamofire.Response<Model.ModelType,APIError<ErrorModel>> -> Void)) -> Alamofire.Request? {
        if stubbingEnabled {
            apiStub.performStubWithCompletion(completion)
            return nil
        }
        return performAlamofireRequest { response in
            dispatch_async(self.resultDeliveryQueue) {
                completion(response)
            }
        }
    }
    
    private func performAlamofireRequest(completion : Response<Model.ModelType,APIError<ErrorModel>> -> Void) -> Alamofire.Request
    {
        guard let manager = tronDelegate?.manager else {
            fatalError("Manager cannot be nil while performing APIRequest")
        }
        let request = alamofireRequest(from: manager)
        if !tronDelegate!.manager.startRequestsImmediately {
            request.resume()
        }
        // Notify plugins about new network request
        let allPlugins = plugins + (tronDelegate?.plugins ?? [])
        allPlugins.forEach {
            $0.willSendRequest(request.request)
        }
        return request.validate().response(queue: processingQueue,responseSerializer: responseSerializer(notifyingPlugins: allPlugins), completionHandler: completion)
    }
    
    private func performAlamofireRequest(success: Model.ModelType -> Void, failure: (APIError<ErrorModel> -> Void)?) -> Alamofire.Request
    {
        return performAlamofireRequest {
            self.callSuccessFailureBlocks(success, failure: failure, response: $0)
        }
    }
}

extension NSData {
    func parseToAnyObject() throws -> AnyObject {
        return try NSJSONSerialization.JSONObjectWithData(self, options: .AllowFragments)
    }
}