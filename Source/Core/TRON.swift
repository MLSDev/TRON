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
open class TRON : TronDelegate {
    
    /// Header builder to be used by default in all requests. Can be overridden for specific requests.
    open var headerBuilder : HeaderBuildable = HeaderBuilder(defaultHeaders: ["Accept":"application/json"])
    
    /// URL builder to be used by default in all requests. Can be overridden for specific requests.
    open var urlBuilder : URLBuildable
    
    /// Global property, that defines whether stubbing is enabled. It is simply set on each `APIRequest` instance and can be reset.
    open var stubbingEnabled = false
    
    /// Global property, that defines whether stubbing should be successful. It propogates to `APIRequest.apiStub.successful` property on creation of the request. Defaults to `true`.
    open var stubbingShouldBeSuccessful = true
    
    /// Global plugins, that will receive events from all requests, created from current TRON instance.
    open var plugins : [Plugin] = []
    
    /// Encoding strategy, based on HTTP Method. Strategy will be set for all APIRequests, and can be overrided by setting new value on APIRequest.encodingStrategy property.
    /// Default value - TRON.RESTEncodingStrategy
    open var encodingStrategy = TRON.RESTEncodingStrategy()
    
    /// Queue, used for processing response, received from the server. Defaults to QOS_CLASS_USER_INITIATED queue
    open var processingQueue = DispatchQueue.global(qos: .userInitiated)
    
    /// Queue, used to deliver result completion blocks. Defaults to dispatch_get_main_queue().
    open var resultDeliveryQueue = DispatchQueue.main
    
    /// Alamofire.Manager instance used to send network requests
    open let manager : Alamofire.SessionManager
    
    /**
     Initializes `TRON` with given base URL, Alamofire.Manager instance, and array of global plugins.
     
     - parameter baseURL: Base URL to be used 
     
     - parameter manager: Alamofire.Manager instance that will send requests created by current `TRON`
     
     - parameter plugins: Array of plugins, that will receive events from requests, created and managed by current `TRON` instance.
     */
    public init(baseURL: String,
        manager: Alamofire.SessionManager = TRON.defaultAlamofireManager(),
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
    open func request<Model:Parseable, ErrorModel:Parseable>(_ path: String) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: .default,path: path, tron: self)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadFromFile.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter fileURL: File url to upload from.
     
     - returns: APIRequest instance.
     */
    open func upload<Model:Parseable, ErrorModel:Parseable>(_ path: String, fromFileAt fileURL: URL) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.uploadFromFile(fileURL), path: path, tron: self)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadData.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter data: Data to upload.
     
     - returns: APIRequest instance.
     */
    open func upload<Model:Parseable, ErrorModel:Parseable>(_ path: String, data: Data) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.uploadData(data), path: path, tron: self)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadStream.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter stream: Stream to upload from.
     
     - returns: APIRequest instance.
     */
    open func upload<Model:Parseable, ErrorModel:Parseable>(_ path: String, from stream: InputStream) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.uploadStream(stream), path: path, tron: self)
    }
    
    /**
     Creates MultipartAPIRequest with specified relative path.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter formData: Multipart form data creation block.
     
     - returns: MultipartAPIRequest instance.
     */
    open func uploadMultipart<Model:Parseable, ErrorModel:Parseable>(_ path: String, formData: @escaping (MultipartFormData) -> Void) -> MultipartAPIRequest<Model,ErrorModel> {
        return MultipartAPIRequest(path: path, tron: self, multipartFormData: formData)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.Download.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination for downloading.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    open func download<Model:Parseable, ErrorModel:Parseable>(_ path: String, to destination: Request.DownloadFileDestination) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.download(destination), path: path, tron: self)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.DownloadResuming.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination to download to.
     
     - parameter resumingFrom: Resume data for current request.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    open func download<Model:Parseable, ErrorModel:Parseable>(_ path: String, to destination: Request.DownloadFileDestination, resumingFrom: Data) -> APIRequest<Model,ErrorModel> {
        return APIRequest(type: RequestType.downloadResuming(data: resumingFrom, destination: destination), path: path, tron: self)
    }
    
    /**
     Default Alamofire.Manager instance to be used by `TRON`.
     
     - returns Alamofire.Manager instance initialized with NSURLSessionConfiguration.defaultSessionConfiguration().
     */
    open static func defaultAlamofireManager() -> SessionManager {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        let manager = SessionManager(configuration: configuration)
        return manager
    }
    
    /**
     Encoding strategy, which always sets .URL encoding for requests.
     */
    open static func URLEncodingStrategy() -> (Alamofire.HTTPMethod) -> Alamofire.ParameterEncoding {
        return { method in
            return .url
        }
    }
    
    /**
     REST encoding strategy. .post, .put, .patch methods use .json encoding, all others - .url encoding.
     
     - Note: This strategy is used by default.
     */
    open static func RESTEncodingStrategy() -> (Alamofire.HTTPMethod) -> Alamofire.ParameterEncoding {
        return { method in
            switch method
            {
            case .post, .put, .patch : return .json
            default: return .url
            }
        }
    }
}

// DEPRECATED

extension TRON {
    @available(*,unavailable,renamed:"upload(_:fromFileAt:)")
    open func upload<Model:Parseable, ErrorModel:Parseable>(_ path: String, file: URL) -> APIRequest<Model,ErrorModel> {
        fatalError("UNAVAILABLE")
    }
    
    @available(*,unavailable,renamed:"upload(_:from:)")
    open func upload<Model:Parseable, ErrorModel:Parseable>(_ path: String, stream: InputStream) -> APIRequest<Model,ErrorModel> {
        fatalError("UNAVAILABLE")
    }
    
    @available(*,unavailable,renamed:"download(_:to:)")
    open func download<Model:Parseable, ErrorModel:Parseable>(_ path: String, destination: Request.DownloadFileDestination) -> APIRequest<Model,ErrorModel> {
        fatalError("UNAVAILABLE")
    }
    
    @available(*,unavailable,renamed:"download(_:to:resumingFrom:)")
    open func download<Model:Parseable, ErrorModel:Parseable>(_ path: String, destination: Request.DownloadFileDestination, resumingFromData: Data) -> APIRequest<Model,ErrorModel> {
        fatalError("UNAVAILABLE")
    }
}
