//
//  APIRequest.swift
//  Hint
//
//  Created by Anton Golikov on 08.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import Alamofire
import SwiftyJSON

protocol Cancellable {
    func cancel()
}

extension Alamofire.Request : Cancellable {}

protocol NSURLBuildable {
    func urlForPath(path: String) -> NSURL
}

protocol HeaderBuildable {
    func headersForAuthorization(requirement: AuthorizationRequirement, headers: [String:String]) -> [String: String]
}

class APIRequest<Model: JSONDecodable, ErrorModel: JSONDecodable> {
    
    var path: String
    var method: Alamofire.Method = .GET
    var parameters: [String: AnyObject] = [:]
    var headers : [String:String] = [:]
    var encoding: Alamofire.ParameterEncoding = .URL
    var authorizationRequirement = AuthorizationRequirement.Required
    
    var headerBuilder = APIRequestConfigurator.headerBuilder
    var urlBuilder = APIRequestConfigurator.urlBuilder
    var responseBuilder = ResponseBuilder<Model>()
    var errorBuilder = ErrorBuilder<ErrorModel>()
    
    var stubbingEnabled = APIRequestConfigurator.stubbingEnabled
    var apiStub = APIStub<Model, ErrorModel>()
    
    var plugins : [Plugin] = []
    private var globalPlugins : [Plugin] {
        return APIRequestConfigurator.plugins
    }
    
    var allPlugins: [Plugin] {
        return globalPlugins + plugins
    }
    
    init(path: String) {
        self.path = path
    }
    
    func performWithSuccess(success: Model -> Void, failure: (APIError<ErrorModel> -> Void)? = nil) -> Cancellable
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
        allPlugins.forEach {
            $0.willSendRequest(alamofireRequest.request)
        }
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

enum AuthorizationRequirement {
    case None, Allowed, Required
}