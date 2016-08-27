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
    case `default`
    
    /// Will create `NSURLSessionUploadTask` using `uploadTaskWithRequest(_:fromFile:)` method
    case uploadFromFile(URL)
    
    /// Will create `NSURLSessionUploadTask` using `uploadTaskWithRequest(_:fromData:)` method
    case uploadData(Data)
    
    /// Will create `NSURLSessionUploadTask` using `uploadTaskWithStreamedRequest(_)` method
    case uploadStream(InputStream)
    
    /// Will create `NSURLSessionDownloadTask` using `downloadTaskWithRequest(_)` method
    case download(Request.DownloadFileDestination)
    
    /// Will create `NSURLSessionDownloadTask` using `downloadTaskWithResumeData(_)` method
    case downloadResuming(data: Data, destination: Request.DownloadFileDestination)
}

/**
 `APIRequest` encapsulates request creation logic, stubbing options, and response/error parsing. It is reusable and configurable for any needs.
 */
open class APIRequest<Model: Parseable, ErrorModel: Parseable>: BaseRequest<Model,ErrorModel> {
    
    internal let requestType: RequestType
    
    internal func alamofireRequest(from manager: Alamofire.SessionManager) -> Alamofire.Request {
        switch requestType {
        case .default:
            return manager.request(urlBuilder.urlForPath(path), withMethod: method,
                                   parameters: parameters,
                                   encoding: encodingStrategy(method),
                                   headers:  headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers))
            
        case .uploadFromFile(let url):
            return manager.upload(url, to: urlBuilder.urlForPath(path), withMethod: method, headers: headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers))
        
        case .uploadData(let data):
            return manager.upload(data, to: urlBuilder.urlForPath(path), withMethod: method, headers: headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers))
            
        case .uploadStream(let stream):
            return manager.upload(stream, to: urlBuilder.urlForPath(path), withMethod: method, headers: headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers))
            
        case .download(let destination):
            return manager.download(urlBuilder.urlForPath(path), to: destination, withMethod: method,
                                    parameters: parameters,
                                    encoding: encodingStrategy(method),
                                    headers: headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers))
        
        case .downloadResuming(let data, let destination):
            return manager.download(resourceWithin: data, to: destination)
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
    
    /**
     Send current request.
     
     - parameter success: Success block to be executed when request finished
     
     - parameter failure: Failure block to be executed if request fails. Nil by default.
     
     - returns: Alamofire.Request or nil if request was stubbed.
     */
    @discardableResult
    open func perform(_ success: ((Model) -> Void)? = nil, failure: ((APIError<ErrorModel>) -> Void)? = nil) -> Alamofire.Request?
    {
        if stubbingEnabled {
            apiStub.performStubWithSuccess(success, failure: failure)
            return nil
        }
        return performAlamofireRequest(success, failure: failure)
    }
    
    @available(*,unavailable,renamed:"performCollectingTimeline")
    @discardableResult
    open func perform(_ completion: ((Alamofire.Response<Model,APIError<ErrorModel>>) -> Void)) -> Alamofire.Request? {
        return nil
    }
    /**
     Perform current request with completion block, that contains Alamofire.Response.
     
     - parameter completion: Alamofire.Response completion block.
     
     - returns: Alamofire.Request or nil if request was stubbed.
    */
    @discardableResult
    open func performCollectingTimeline(withCompletion completion: ((Alamofire.Response<Model,APIError<ErrorModel>>) -> Void)) -> Alamofire.Request? {
        if stubbingEnabled {
            apiStub.performStubWithCompletion(completion)
            return nil
        }
        return performAlamofireRequest { response in
            self.resultDeliveryQueue.async() {
                completion(response)
            }
        }
    }
    
    fileprivate func performAlamofireRequest(_ completion : @escaping (Response<Model,APIError<ErrorModel>>) -> Void) -> Alamofire.Request
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
    
    fileprivate func performAlamofireRequest(_ success: ((Model) -> Void)?, failure: ((APIError<ErrorModel>) -> Void)?) -> Alamofire.Request
    {
        return performAlamofireRequest {
            self.callSuccessFailureBlocks(success, failure: failure, response: $0)
        }
    }
}
