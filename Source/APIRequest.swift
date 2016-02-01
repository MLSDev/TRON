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
import SwiftyJSON

/**
 `RequestToken` instance is returned by APIRequest instance, when request is sent. Based on whether stubbing is enabled or not, it can be an `Alamofire.Request` instance or `TRON.APIStub` instance.
 */
public protocol RequestToken : CustomStringConvertible, CustomDebugStringConvertible {
    
    /// Cancel current request
    func cancel()
}

extension Alamofire.Request : RequestToken {}

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

/**
 `APIRequest` encapsulates request creation logic, stubbing options, and response/error parsing. It is reusable and configurable for any needs.
 */
public class APIRequest<Model: JSONDecodable, ErrorModel: JSONDecodable> {
    
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
    
    /// Delegate property that is used to communicate with `TRON` instance.
    weak var tronDelegate : TronDelegate?
    
    /// Array of plugins for current `APIRequest`.
    public var plugins : [Plugin] = []
    
    /**
    Initialize request with relative path and `TRON` instance.
     
     - parameter path: relative path to resource.
     
     - parameter tron: `TRON` instance to be used to configure current request.
     */
    public init(path: String, tron: TRON) {
        self.path = path
        self.tronDelegate = tron
        self.stubbingEnabled = tron.stubbingEnabled
        self.headerBuilder = tron.headerBuilder
        self.urlBuilder = tron.urlBuilder
    }
    
    /**
     Send current request.
     
     - parameter success: Success block to be executed when request finished
     
     - parameter failure: Failure block to be executed if request fails. Nil by default.
     
     - returns: Request token, that can be used to cancel request, or print debug information.
     */
    public func performWithSuccess(success: Model -> Void, failure: (APIError<ErrorModel> -> Void)? = nil) -> RequestToken
    {
        if stubbingEnabled {
            return apiStub.performStubWithSuccess(success, failure: failure)
        }
        return performAlamofireRequest(success, failure: failure)
    }
    
    private func performAlamofireRequest(success: Model -> Void, failure: (APIError<ErrorModel> -> Void)?) -> RequestToken
    {
        guard let manager = tronDelegate?.manager else {
            fatalError("Manager cannot be nil while performing APIRequest")
        }
        let alamofireRequest = manager.request(method, urlBuilder.urlForPath(path),
            parameters: parameters,
            encoding: encoding,
            headers:  headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers))
        
        // Notify plugins about new network request
        tronDelegate?.plugins.forEach {
            $0.willSendRequest(alamofireRequest.request)
        }
        plugins.forEach {
            $0.willSendRequest(alamofireRequest.request)
        }
        let allPlugins = plugins + (tronDelegate?.plugins ?? [])
        alamofireRequest.validate().handleResponse(success,
            failure: failure,
            responseBuilder: responseBuilder,
            errorBuilder: errorBuilder,
            plugins: allPlugins)
        return alamofireRequest
    }
}

extension Alamofire.Request {
    func handleResponse<Model: JSONDecodable, ErrorModel: JSONDecodable>(success: Model -> Void,
        failure: (APIError<ErrorModel> -> Void)?,
        responseBuilder: ResponseBuilder<Model>,
        errorBuilder: ErrorBuilder<ErrorModel>, plugins: [Plugin]) -> Self
    {
        return response { urlRequest, response, data, error in
            
            // Notify plugins that request finished loading
            plugins.forEach {
                $0.requestDidReceiveResponse(urlRequest, response,data,error)
            }
            
            guard error == nil else {
                failure?(errorBuilder.buildErrorFromRequest(urlRequest, response: response, data: data, error: error))
                return
            }
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), {
                let model = responseBuilder.buildResponseFromJSON(JSON(data: data ?? NSData()))
                dispatch_async(dispatch_get_main_queue(), {
                    success(model)
                })
            })
        }
    }
}