//
//  APIRequest.swift
//  Hint
//
//  Created by Anton Golikov on 08.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import Alamofire
import SwiftyJSON

public protocol Cancellable {
    func cancel()
}

extension Alamofire.Request : Cancellable {}

public protocol NSURLBuildable {
    func urlForPath(path: String) -> NSURL
}

public protocol HeaderBuildable {
    func headersForAuthorization(requirement: AuthorizationRequirement, headers: [String:String]) -> [String: String]
}

public enum AuthorizationRequirement {
    case None, Allowed, Required
}

public class APIRequest<Model: JSONDecodable, ErrorModel: JSONDecodable> {
    
    public let path: String
    public var method: Alamofire.Method = .GET
    public var parameters: [String: AnyObject] = [:]
    public var headers : [String:String] = [:]
    public var encoding: Alamofire.ParameterEncoding = .URL
    public var authorizationRequirement = AuthorizationRequirement.Required
    
    public var headerBuilder: HeaderBuildable
    public var urlBuilder: NSURLBuildable
    public var responseBuilder = ResponseBuilder<Model>()
    public var errorBuilder = ErrorBuilder<ErrorModel>()
    
    public var stubbingEnabled = false
    public var apiStub = APIStub<Model, ErrorModel>()
    
    weak var tron : TRON?
    
    public var plugins : [Plugin] = []
    
    public init(path: String, tron: TRON) {
        self.path = path
        self.tron = tron
        self.stubbingEnabled = tron.stubbingEnabled
        self.headerBuilder = tron.headerBuilder
        self.urlBuilder = tron.urlBuilder
    }
    
    public func performWithSuccess(success: Model -> Void, failure: (APIError<ErrorModel> -> Void)? = nil) -> Cancellable
    {
        if stubbingEnabled {
            return apiStub.performStubWithSuccess(success, failure: failure)
        }
        return performAlamofireRequest(success, failure: failure)
    }
    
    private func performAlamofireRequest(success: Model -> Void, failure: (APIError<ErrorModel> -> Void)?) -> Cancellable
    {
        let alamofireRequest = Alamofire.request(method, urlBuilder.urlForPath(path), parameters: parameters, encoding: encoding, headers: headerBuilder.headersForAuthorization(authorizationRequirement, headers: headers))
        // Notify plugins about new network request
        tron?.plugins.forEach {
            $0.willSendRequest(alamofireRequest.request)
        }
        plugins.forEach {
            $0.willSendRequest(alamofireRequest.request)
        }
        let allPlugins = plugins + (tron?.plugins ?? [])
        alamofireRequest.validate().handleResponse(success,
            failure: failure,
            responseBuilder: responseBuilder,
            errorBuilder: errorBuilder, plugins: allPlugins)
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