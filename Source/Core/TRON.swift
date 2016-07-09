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
    
    /// Global property, that defines whether stubbing should be successful. It propogates to `APIRequest.apiStub.successful` property on creation of the request. Defaults to `true`.
    public var stubbingShouldBeSuccessful = true
    
    /// Global plugins, that will receive events from all requests, created from current TRON instance.
    public var plugins : [Plugin] = []
    
    /// Encoding strategy, based on HTTP Method. Strategy will be set for all APIRequests, and can be overrided by setting new value on APIRequest.encodingStrategy property.
    /// Default value - TRON.URLEncodingStrategy, which always sets .URL encoding.
    /// - Note: This behaviour will be changed in following releases to use TRON.RESTEncodingStrategy.
    public var encodingStrategy = TRON.URLEncodingStrategy()
    
    /// Queue, used for processing response, received from the server. Defaults to QOS_CLASS_USER_INITIATED queue
    public var processingQueue = DispatchQueue.global(attributes: [.qosUserInitiated])
    
    /// Queue, used to deliver result completion blocks. Defaults to dispatch_get_main_queue().
    public var resultDeliveryQueue = DispatchQueue.main
    
    /// Alamofire.Manager instance used to send network requests
    public let manager : Alamofire.Manager
    
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
     Creates APIRequest with specified relative path and type RequestType.Default.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - returns: APIRequest instance.
     */
    public func request<Model:ResponseParseable, ErrorModel:ResponseParseable>(path: String) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: .default,path: path, tron: self)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadFromFile.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter file: File url to upload from.
     
     - returns: APIRequest instance.
     */
    public func upload<Model:ResponseParseable, ErrorModel:ResponseParseable>(path: String, file: URL) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.uploadFromFile(file), path: path, tron: self)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadData.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter data: Data to upload.
     
     - returns: APIRequest instance.
     */
    public func upload<Model:ResponseParseable, ErrorModel:ResponseParseable>(path: String, data: Data) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.uploadData(data), path: path, tron: self)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadStream.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter stream: Stream to upload from.
     
     - returns: APIRequest instance.
     */
    public func upload<Model:ResponseParseable, ErrorModel:ResponseParseable>(path: String, stream: InputStream) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.uploadStream(stream), path: path, tron: self)
    }
    
    /**
     Creates MultipartAPIRequest with specified relative path.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter formData: Multipart form data creation block.
     
     - returns: MultipartAPIRequest instance.
     */
    public func uploadMultipart<Model:ResponseParseable, ErrorModel:ResponseParseable>(path: String, formData: (MultipartFormData) -> Void) -> MultipartAPIRequest<Model,ErrorModel> {
        return MultipartAPIRequest(path: path, tron: self, multipartFormData: formData)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.Download.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination to download to.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    public func download<Model:ResponseParseable, ErrorModel:ResponseParseable>(path: String, destination: Request.DownloadFileDestination) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.download(destination), path: path, tron: self)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.DownloadResuming.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination to download to.
     
     - parameter resumingFromData: Resume data for current request.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    public func download<Model:ResponseParseable, ErrorModel:ResponseParseable>(path: String, destination: Request.DownloadFileDestination, resumingFromData: Data) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.downloadResuming(data: resumingFromData, destination: destination), path: path, tron: self)
    }
    
    /**
     Default Alamofire.Manager instance to be used by `TRON`.
     
     - returns Alamofire.Manager instance initialized with NSURLSessionConfiguration.defaultSessionConfiguration().
     */
    public final class func defaultAlamofireManager() -> Manager {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Manager.defaultHTTPHeaders
        let manager = Manager(configuration: configuration)
        return manager
    }
    
    /**
     Encoding strategy, which always sets .URL encoding for requests.
     */
    public static func URLEncodingStrategy() -> (Alamofire.Method) -> Alamofire.ParameterEncoding {
        return { method in
            return .url
        }
    }
    
    /**
     REST encoding strategy. OPTIONS, GET, HEAD, DELETE, TRACE, CONNECT HTTP methods use .URL encoding, POST, PUT and PATCH - use JSON encoding.
     
     - Note: This strategy will become default in following releases. It's advised to use it for best practices.
     */
    public static func RESTEncodingStrategy() -> (Alamofire.Method) -> Alamofire.ParameterEncoding {
        return { method in
            switch method
            {
            case .POST, .PUT, .PATCH : return .json
            default: return .url
            }
        }
    }
}
