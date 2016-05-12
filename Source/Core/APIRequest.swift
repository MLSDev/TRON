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

/// Typealias for typical Progress definition in networking frameworks
public typealias Progress = (bytesSent: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
/// Typealias for typical progress closure
public typealias ProgressClosure = Progress -> Void

/**
 Protocol, that defines how NSURL is constructed by consumer.
 */
public protocol NSURLBuildable {
    
    /**
     Construct NSURL with given path
     
     - parameter path: relative path
     
     - returns constructed NSURL
     */
    func urlForPath(path: String) -> NSURL
}

/**
 Protocol, that defines how headers should be constructed by consumer.
 */
public protocol HeaderBuildable {
    
    /**
     Construct headers for specific request.
     
     - parameter requirement: Authorization requirement of current request
     
     - parameter headers : headers to be included in this specific request
     
     - returns: HTTP headers for current request
     */
    func headersForAuthorization(requirement: AuthorizationRequirement, headers: [String:String]) -> [String: String]
}

/**
    Authorization requirement for current request.
 */
public enum AuthorizationRequirement {
    
    /// Request does not need authorization
    case None
    
    /// Request can have authorization, and may receive additional fields in response
    case Allowed
    
    /// Request requires authorization
    case Required
}

/// Protocol used to allow `APIRequest` to communicate with `TRON` instance.
public protocol TronDelegate: class {
    
    /// Alamofire.Manager used to send requests
    var manager: Alamofire.Manager { get }
    
    /// Global array of plugins on `TRON` instance
    var plugins : [Plugin] { get }
}

public enum RequestType {
    case Default
    
    case UploadFromFile(NSURL)
    case UploadData(NSData)
    case UploadStream(NSInputStream)
    case UploadMultipart(MultipartFormData -> Void)
    
    case Download(Request.DownloadFileDestination)
    case DownloadResuming(data: NSData, destination: Request.DownloadFileDestination)
}

/**
 `APIRequest` encapsulates request creation logic, stubbing options, and response/error parsing. It is reusable and configurable for any needs.
 */
public class APIRequest<Model: ResponseParseable, ErrorModel: ResponseParseable> {
    
    /// Relative path of current request
    public let path: String
    
    /// HTTP method
    public var method: Alamofire.Method = .GET
    
    /// Parameters of current request
    public var parameters: [String: AnyObject] = [:]
    
    /// Parameter encoding option.
    public var encoding: Alamofire.ParameterEncoding = .URL
    
    /// Headers, that should be used for current request.
    /// - Note: Resulting headers may include global headers from `TRON` instance and `Alamofire.Manager` defaultHTTPHeaders.
    public var headers : [String:String] = [:]
    
    /// Authorization requirement for current request
    public var authorizationRequirement = AuthorizationRequirement.None
    
    /// Header builder for current request
    public var headerBuilder: HeaderBuildable
    
    /// URL builder for current request
    public var urlBuilder: NSURLBuildable
    
    /// Response builder for current request
    public var responseBuilder = ResponseBuilder<Model>()
    
    /// Error builder for current request
    public var errorBuilder = ErrorBuilder<ErrorModel>()
    
    /// Is stubbing enabled for current request?
    public var stubbingEnabled = false
    
    /// API stub to be used when stubbing this request
    public var apiStub = APIStub<Model, ErrorModel>()
    
    /// Queue, used for processing response, received from the server. Defaults to TRON.processingQueue queue.
    public var processingQueue : dispatch_queue_t
    
    /// Queue, used to deliver result completion blocks. Defaults to TRON.resultDeliveryQueue queue.
    public var resultDeliveryQueue : dispatch_queue_t
    
    /// Delegate property that is used to communicate with `TRON` instance.
    weak var tronDelegate : TronDelegate?
    
    /// Array of plugins for current `APIRequest`.
    public var plugins : [Plugin] = []
    
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
            
        case .UploadMultipart(_):
            fatalError("Cannot create Alamofire.Request synchronously for UploadMultipart request type")
            
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
        self.path = path
        self.tronDelegate = tron
        self.stubbingEnabled = tron.stubbingEnabled
        self.headerBuilder = tron.headerBuilder
        self.urlBuilder = tron.urlBuilder
        self.requestType = type
        self.processingQueue = tron.processingQueue
        self.resultDeliveryQueue = tron.resultDeliveryQueue
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
     
     - returns: Request token, that can be used to cancel request, or print debug information.
     */
    public func perform(success success: Model.ModelType -> Void, failure: (APIError<ErrorModel> -> Void)? = nil) -> Alamofire.Request?
    {
        if stubbingEnabled {
            apiStub.performStubWithSuccess(success, failure: failure)
            return nil
        }
        if case RequestType.UploadMultipart(_) = requestType {
            fatalError("Usage of performWithSuccess:failure: method is forbidden with RequestType.UploadMultipart, please use performMultipartUpload: method")
        }
        return performAlamofireRequest(success, failure: failure)
    }
    
    public func perform(completion completion: (Alamofire.Response<Model.ModelType,APIError<ErrorModel>> -> Void)) -> Alamofire.Request? {
        if stubbingEnabled {
            apiStub.performStubWithCompletion(completion)
            return nil
        }
        if case RequestType.UploadMultipart(_) = requestType {
            fatalError("Usage of performWithSuccess:failure: method is forbidden with RequestType.UploadMultipart, please use performMultipartUpload: method")
        }
        return performAlamofireRequest { response in
            dispatch_async(self.resultDeliveryQueue) {
                completion(response)
            }
        }
    }
    
    public func performMultipartUpload(success success: Model.ModelType -> Void, failure: (APIError<ErrorModel> -> Void)? = nil, encodingMemoryThreshold: UInt64 = Manager.MultipartFormDataEncodingMemoryThreshold, encodingCompletion: (Manager.MultipartFormDataEncodingResult -> Void)? = nil)
    {
        guard let manager = tronDelegate?.manager else {
            fatalError("Manager cannot be nil while performing APIRequest")
        }
        
        if stubbingEnabled {
            apiStub.performStubWithSuccess(success, failure: failure)
            return
        }
        
        guard case let RequestType.UploadMultipart(formData) = requestType else {
            fatalError("Unable to call performMultipartUpload for request of type: \(requestType)")
        }
        
        let multipartConstructionBlock: MultipartFormData -> Void = { requestFormData in
            self.parameters.forEach { (key,value) in
                requestFormData.appendBodyPart(data: String(value).dataUsingEncoding(NSUTF8StringEncoding) ?? NSData(), name: key)
            }
            formData(requestFormData)
        }
        
        let encodingCompletion: Manager.MultipartFormDataEncodingResult -> Void = { completion in
            if case .Failure(let error) = completion {
                let apiError = APIError<ErrorModel>(request: nil, response: nil, data: nil, error: error as NSError)
                failure?(apiError)
            } else if case .Success(let request, _, _) = completion {
                let allPlugins = self.plugins + (self.tronDelegate?.plugins ?? [])
                allPlugins.forEach {
                    $0.willSendRequest(request.request)
                }
                request.validate().response(queue : self.processingQueue,
                                            responseSerializer: self.responseSerializer(notifyingPlugins:allPlugins))
                {
                    self.callSuccessFailureBlocks(success, failure: failure, response: $0)
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
    
    private func performAlamofireRequest(completion : Response<Model.ModelType,APIError<ErrorModel>> -> Void) -> Alamofire.Request
    {
        guard let manager = tronDelegate?.manager else {
            fatalError("Manager cannot be nil while performing APIRequest")
        }
        let request = alamofireRequest(from: manager)
        
        // Notify plugins about new network request
        let allPlugins = plugins + (tronDelegate?.plugins ?? [])
        allPlugins.forEach {
            $0.willSendRequest(request.request)
        }
        return request.validate().response(queue: processingQueue,responseSerializer: responseSerializer(notifyingPlugins: allPlugins), completionHandler: completion)
    }
    
    private func callSuccessFailureBlocks(success: Model.ModelType -> Void,
                                          failure: (APIError<ErrorModel> -> Void)?,
                                          response: Alamofire.Response<Model.ModelType,APIError<ErrorModel>>) {
        switch response.result
        {
        case .Success(let value):
            dispatch_async(resultDeliveryQueue) {
                success(value)
            }
        case .Failure(let error):
            dispatch_async(resultDeliveryQueue) {
                failure?(error)
            }
        }
    }
    
    private func performAlamofireRequest(success: Model.ModelType -> Void, failure: (APIError<ErrorModel> -> Void)?) -> Alamofire.Request
    {
        return performAlamofireRequest {
            self.callSuccessFailureBlocks(success, failure: failure, response: $0)
        }
    }
    
    private func responseSerializer(notifyingPlugins plugins: [Plugin]) -> Alamofire.ResponseSerializer<Model.ModelType,APIError<ErrorModel>> {
        return ResponseSerializer<Model.ModelType,APIError<ErrorModel>> { urlRequest, response, data, error in
            dispatch_async(dispatch_get_main_queue()) {
                plugins.forEach {
                    $0.requestDidReceiveResponse(urlRequest, response,data,error)
                }
            }
            guard error == nil else {
                return .Failure(self.errorBuilder.buildErrorFromRequest(urlRequest, response: response, data: data, error: error))
            }
            if Model.self is EmptyResponse.Type {
                return .Success(EmptyResponse() as! Model.ModelType)
            }
            let object : AnyObject
            do {
                object = try (data ?? NSData()).parseToAnyObject()
            }
            catch let jsonError as NSError {
                return .Failure(self.errorBuilder.buildErrorFromRequest(urlRequest, response: response, data: data, error: jsonError))
            }
            let model: Model.ModelType
            do {
                model = try self.responseBuilder.buildResponseFromJSON(object)
            }
            catch let parsingError as NSError {
                return .Failure(self.errorBuilder.buildErrorFromRequest(urlRequest, response: response, data: data, error: parsingError))
            }
            return .Success(model)
        }
    }
}

extension NSData {
    func parseToAnyObject() throws -> AnyObject {
        return try NSJSONSerialization.JSONObjectWithData(self, options: .AllowFragments)
    }
}