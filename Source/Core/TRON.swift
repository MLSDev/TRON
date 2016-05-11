//
//  TRON.swift
//  TRON
//
//  Created by Denys Telezhkin on 28.01.16.
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

import Foundation
import Alamofire

/**
 `TRON` is a root object, that serves as a provider for single API endpoint. It is used to create and configure instances of `APIRequest` and `MultipartAPIRequest`.
 
 You need to hold strong reference to `TRON` instance while your network requests are running.
 */
public class TRON : TronDelegate {
    
    /// Header builder to be used by default in all requests. Can be overridden for specific requests.
    public var headerBuilder : HeaderBuildable = HeaderBuilder(defaultHeaders: ["Accept":"application/json"])
    
    /// NSURL builder to be used by default in all requests. Can be overridden for specific requests.
    public var urlBuilder : NSURLBuildable
    
    /// Global property, that defines whether stubbing is enabled. It is simply set on each `APIRequest` instance and can be reset.
    public var stubbingEnabled = false
    
    /// Global plugins, that will receive events from all requests, created from current TRON instance.
    public var plugins : [Plugin] = []
    
    /// Alamofire.Manager instance used to send network requests
    public let manager : Alamofire.Manager
    
    /// Object, responsible for calling success and failure completion blocks on specified GCD queues. When `APIRequest` object is created, it is automatically configured with current dispatcher instance.
    public var dispatcher = EventDispatcher()
    
    /**
     Initializes `TRON` with given base URL, Alamofire.Manager instance, and array of global plugins.
     
     - parameter baseURL: Base URL to be used 
     
     - parameter manager: Alamofire.Manager instance that will send requests created by current `TRON`
     
     - parameter plugins: Array of plugins, that will receive events from requests, created and managed by current `TRON` instance.
     */
    public init(baseURL: String,
        manager: Alamofire.Manager = TRON.defaultAlamofireManager(),
        plugins : [Plugin] = [])
    {
        self.urlBuilder = URLBuilder(baseURL: baseURL)
        self.plugins = plugins
        self.manager = manager
    }
    
    /**
     Creates APIRequest with specified relative path.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - returns APIRequest instance.
     */
    public func request<Model:ResponseParseable, ErrorModel:ResponseParseable>(path path: String) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: .Default,path: path, tron: self)
    }
    
    public func upload<Model:ResponseParseable, ErrorModel:ResponseParseable>(path path: String, file: NSURL) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.UploadFromFile(file), path: path, tron: self)
    }
    
    public func upload<Model:ResponseParseable, ErrorModel:ResponseParseable>(path path: String, data: NSData) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.UploadData(data), path: path, tron: self)
    }
    
    public func upload<Model:ResponseParseable, ErrorModel:ResponseParseable>(path path: String, stream: NSInputStream) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.UploadStream(stream), path: path, tron: self)
    }
    
    public func upload<Model:ResponseParseable, ErrorModel:ResponseParseable>(path path: String, formData: MultipartFormData -> Void) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.UploadMultipart(formData), path: path, tron: self)
    }
    
    public func download<Model:ResponseParseable, ErrorModel:ResponseParseable>(path path: String, destination: Request.DownloadFileDestination) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.Download(destination), path: path, tron: self)
    }
    
    public func download<Model:ResponseParseable, ErrorModel:ResponseParseable>(path path: String, destination: Request.DownloadFileDestination, resumingFromData: NSData) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.DownloadResuming(data: resumingFromData, destination: destination), path: path, tron: self)
    }
    
    /**
     Default Alamofire.Manager instance to be used by `TRON`.
     
     - returns Alamofire.Manager instance initialized with NSURLSessionConfiguration.defaultSessionConfiguration().
     */
    public final class func defaultAlamofireManager() -> Manager {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        let manager = Manager(configuration: configuration)
        return manager
    }
}
