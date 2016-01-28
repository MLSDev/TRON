//
//  TRON.swift
//  TRON
//
//  Created by Denys Telezhkin on 28.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
import Alamofire

public class TRON {
    public var headerBuilder : HeaderBuildable = JSONHeaderBuilder()
    public var urlBuilder : NSURLBuildable
    public var stubbingEnabled = false
    internal var plugins : [Plugin] = []
    public let manager : Alamofire.Manager
    
    public init(baseURL: String,
        manager: Alamofire.Manager = TRON.defaultAlamofireManager(),
        plugins : [Plugin] = [])
    {
        self.urlBuilder = URLBuilder(baseURLString: baseURL)
        self.plugins = plugins
        self.manager = manager
    }
    
    public func request<Model:JSONDecodable, ErrorModel:JSONDecodable>(path path: String) -> APIRequest<Model,ErrorModel> {
        return APIRequest(path: path, tron: self)
    }
    
    public final class func defaultAlamofireManager() -> Manager {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        let manager = Manager(configuration: configuration)
        manager.startRequestsImmediately = false
        return manager
    }
}
