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

public protocol RequestToken : CustomStringConvertible, CustomDebugStringConvertible {
    func cancel()
}

extension Alamofire.Request : RequestToken {}

public protocol NSURLBuildable {
    func urlForPath(path: String) -> NSURL
}

public protocol HeaderBuildable {
    func headersForAuthorization(requirement: AuthorizationRequirement, headers: [String:String]) -> [String: String]
}

public enum AuthorizationRequirement {
    case None, Allowed, Required
}

public protocol TronDelegate: class {
    var manager: Alamofire.Manager { get }
    var plugins : [Plugin] { get }
}

public class APIRequest<Model: JSONDecodable, ErrorModel: JSONDecodable> {
    
    public let path: String
    public var method: Alamofire.Method = .GET
    public var parameters: [String: AnyObject] = [:]
    public var headers : [String:String] = [:]
    public var encoding: Alamofire.ParameterEncoding = .URL
    public var authorizationRequirement = AuthorizationRequirement.None
    
    public var headerBuilder: HeaderBuildable
    public var urlBuilder: NSURLBuildable
    public var responseBuilder = ResponseBuilder<Model>()
    public var errorBuilder = ErrorBuilder<ErrorModel>()
    
    public var stubbingEnabled = false
    public var apiStub = APIStub<Model, ErrorModel>()
    
    weak var tronDelegate : TronDelegate?
    
    public var plugins : [Plugin] = []
    
    public init(path: String, tron: TRON) {
        self.path = path
        self.tronDelegate = tron
        self.stubbingEnabled = tron.stubbingEnabled
        self.headerBuilder = tron.headerBuilder
        self.urlBuilder = tron.urlBuilder
    }
    
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
            headers: headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers))
        
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