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
    func urlForPath(_ path: String) -> URL
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
    func headersForAuthorization(_ requirement: AuthorizationRequirement, headers: [String:String]) -> [String: String]
}

/**
 Authorization requirement for current request.
 */
public enum AuthorizationRequirement {
    
    /// Request does not need authorization
    case none
    
    /// Request can have authorization, and may receive additional fields in response
    case allowed
    
    /// Request requires authorization
    case required
}

/// Protocol used to allow `APIRequest` to communicate with `TRON` instance.
public protocol TronDelegate: class {
    
    /// Alamofire.Manager used to send requests
    var manager: Alamofire.Manager { get }
    
    /// Global array of plugins on `TRON` instance
    var plugins : [Plugin] { get }
}

public class BaseRequest<Model: Parseable, ErrorModel: Parseable> {
    /// Relative path of current request
    public let path: String
    
    /// HTTP method
    public var method: Alamofire.Method = .GET
    
    /// Parameters of current request.
    public var parameters: [String: AnyObject] = [:]
    
    /// Selection of encoding based on HTTP method.
    public var encodingStrategy : (Alamofire.Method) -> Alamofire.ParameterEncoding
    
    /// Headers, that should be used for current request.
    /// - Note: Resulting headers may include global headers from `TRON` instance and `Alamofire.Manager` defaultHTTPHeaders.
    public var headers : [String:String] = [:]
    
    /// Authorization requirement for current request
    public var authorizationRequirement = AuthorizationRequirement.none
    
    /// Header builder for current request
    public var headerBuilder: HeaderBuildable
    
    /// URL builder for current request
    public var urlBuilder: NSURLBuildable
    
    /// Error builder for current request
    public var errorBuilder = ErrorBuilder<ErrorModel>()
    
    /// Is stubbing enabled for current request?
    public var stubbingEnabled = false
    
    /// API stub to be used when stubbing this request
    public var apiStub = APIStub<Model, ErrorModel>()
    
    /// Queue, used for processing response, received from the server. Defaults to TRON.processingQueue queue.
    public var processingQueue : DispatchQueue
    
    /// Queue, used to deliver result completion blocks. Defaults to TRON.resultDeliveryQueue queue.
    public var resultDeliveryQueue : DispatchQueue
    
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
        self.encodingStrategy = tron.encodingStrategy
        self.apiStub.successful = tron.stubbingShouldBeSuccessful
    }
    
    internal func responseSerializer(notifyingPlugins plugins: [Plugin]) -> Alamofire.ResponseSerializer<Model,APIError<ErrorModel>> {
        return ResponseSerializer<Model,APIError<ErrorModel>> { urlRequest, response, data, error in
            DispatchQueue.main.async(execute: { 
                plugins.forEach {
                    $0.requestDidReceiveResponse(urlRequest, response,data,error)
                }
            })
            guard error == nil else {
                return .failure(self.errorBuilder.buildErrorFromRequest(urlRequest, response: response, data: data, error: error))
            }
            let model: Model
            do {
                model = try Model.parse(data: data ?? Data())
            }
            catch let parsingError as NSError {
                return .failure(self.errorBuilder.buildErrorFromRequest(urlRequest, response: response, data: data, error: parsingError))
            }
            return .success(model)
        }
    }
    
    internal func callSuccessFailureBlocks(_ success: ((Model) -> Void)?,
                                           failure: ((APIError<ErrorModel>) -> Void)?,
                                           response: Alamofire.Response<Model,APIError<ErrorModel>>)
    {
        switch response.result
        {
        case .success(let value):
            (resultDeliveryQueue).async {
                success?(value)
            }
        case .failure(let error):
            (resultDeliveryQueue).async {
                failure?(error)
            }
        }
    }
}
