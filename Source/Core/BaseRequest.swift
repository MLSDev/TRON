//
//  BaseRequest.swift
//  TRON
//
//  Created by Denys Telezhkin on 15.05.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
import Alamofire

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

public class BaseRequest<Model: ResponseParseable, ErrorModel: ResponseParseable> {
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
    
    init(path: String, tron: TRON) {
        self.path = path
        self.tronDelegate = tron
        self.stubbingEnabled = tron.stubbingEnabled
        self.headerBuilder = tron.headerBuilder
        self.urlBuilder = tron.urlBuilder
        self.processingQueue = tron.processingQueue
        self.resultDeliveryQueue = tron.resultDeliveryQueue
    }
    
    internal func responseSerializer(notifyingPlugins plugins: [Plugin]) -> Alamofire.ResponseSerializer<Model.ModelType,APIError<ErrorModel>> {
        return ResponseSerializer<Model.ModelType,APIError<ErrorModel>> { urlRequest, response, data, error in
            dispatch_async(dispatch_get_main_queue()) {
                plugins.forEach {
                    $0.requestDidReceiveResponse(urlRequest, response,data,error)
                }
            }
            guard error == nil else {
                return .Failure(self.errorBuilder.buildErrorFromRequest(urlRequest, response: response, data: data, error: error))
            }
            let model: Model.ModelType
            do {
                model = try self.responseBuilder.buildResponseFromData(data ?? NSData())
            }
            catch let parsingError as NSError {
                return .Failure(self.errorBuilder.buildErrorFromRequest(urlRequest, response: response, data: data, error: parsingError))
            }
            return .Success(model)
        }
    }
    
    internal func callSuccessFailureBlocks(success: Model.ModelType -> Void,
                                           failure: (APIError<ErrorModel> -> Void)?,
                                           response: Alamofire.Response<Model.ModelType,APIError<ErrorModel>>)
    {
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
}