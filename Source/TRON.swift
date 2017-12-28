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
    @available(*, deprecated, message: "Global headerBuilder is deprecated and may be removed in future versions of the framework. To have global request customization, please use Alamofire.RequestAdapter - https://github.com/Alamofire/Alamofire/blob/master/Documentation/AdvancedUsage.md#requestadapter")
    open var headerBuilder : HeaderBuildable = HeaderBuilder(defaultHeaders: ["Accept":"application/json"])
    
    /// URL builder to be used by default in all requests. Can be overridden for specific requests.
    open var urlBuilder : URLBuildable
    
    /// Global property, that defines whether stubbing is enabled. It is simply set on each `APIRequest` instance and can be reset.
    open var stubbingEnabled = false
    
    /// Global property, that defines whether stubbing should be successful. It propogates to `APIRequest.apiStub.successful` property on creation of the request. Defaults to `true`.
    open var stubbingShouldBeSuccessful = true
    
    /// Global plugins, that will receive events from all requests, created from current TRON instance.
    open var plugins : [Plugin] = []
    
    /// Default parameter encoding, that will be set on all APIRequests. Can be overrided by setting new value on APIRequest.parameterEncoding property.
    /// Default value - URLEncoding.default
    open var parameterEncoding: Alamofire.ParameterEncoding = URLEncoding.default
    
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
     
     - parameter responseSerializer: object used to serialize response.
     
     - returns: APIRequest instance.
     */
    open func request<Model, ErrorModel, Serializer: ErrorHandlingDataResponseSerializerProtocol>
        (_ path: String, responseSerializer : Serializer) -> APIRequest<Model,ErrorModel>
        where Serializer.SerializedObject == Model, Serializer.SerializedError == ErrorModel
    {
        return APIRequest(path: path, tron: self, responseSerializer: responseSerializer)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadFromFile.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter fileURL: File url to upload from.
     
     - parameter responseSerializer: object used to serialize response.
     
     - returns: APIRequest instance.
     */
    open func upload<Model, ErrorModel, Serializer: ErrorHandlingDataResponseSerializerProtocol>
        (_ path: String, fromFileAt fileURL: URL, responseSerializer : Serializer) -> UploadAPIRequest<Model,ErrorModel>
        where Serializer.SerializedObject == Model, Serializer.SerializedError == ErrorModel
    {
        return UploadAPIRequest(type: .uploadFromFile(fileURL), path: path, tron: self, responseSerializer: responseSerializer)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadData.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter data: Data to upload.
     
     - parameter responseSerializer: object used to serialize response.
     
     - returns: APIRequest instance.
     */
    open func upload<Model, ErrorModel, Serializer: ErrorHandlingDataResponseSerializerProtocol>
        (_ path: String, data: Data, responseSerializer : Serializer) -> UploadAPIRequest<Model,ErrorModel>
        where Serializer.SerializedObject == Model, Serializer.SerializedError == ErrorModel
    {
        return UploadAPIRequest(type: .uploadData(data), path: path, tron: self, responseSerializer: responseSerializer)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadStream.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter stream: Stream to upload from.
     
     - parameter responseSerializer: object used to serialize response.
     
     - returns: APIRequest instance.
     */
    open func upload<Model, ErrorModel, Serializer: ErrorHandlingDataResponseSerializerProtocol>
        (_ path: String, from stream: InputStream, responseSerializer : Serializer) -> UploadAPIRequest<Model,ErrorModel>
        where Serializer.SerializedObject == Model, Serializer.SerializedError == ErrorModel
    {
        return UploadAPIRequest(type: .uploadStream(stream), path: path, tron: self, responseSerializer: responseSerializer)
    }
    
    /**
     Creates MultipartAPIRequest with specified relative path.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter responseSerializer: object used to serialize response.
     
     - parameter formData: Multipart form data creation block.
     
     - returns: MultipartAPIRequest instance.
     */
    open func uploadMultipart<Model, ErrorModel, Serializer: ErrorHandlingDataResponseSerializerProtocol>
        (_ path: String,responseSerializer : Serializer, formData: @escaping (MultipartFormData) -> Void) -> UploadAPIRequest<Model,ErrorModel>
        where Serializer.SerializedObject == Model, Serializer.SerializedError == ErrorModel
    {
        return UploadAPIRequest(type: .multipartFormData(formData), path: path, tron: self, responseSerializer: responseSerializer)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.Download.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination for downloading.
     
     - parameter responseSerializer: object used to serialize response.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    open func download<Model, ErrorModel, Serializer: ErrorHandlingDownloadResponseSerializerProtocol>
        (_ path: String, to destination: @escaping DownloadRequest.DownloadFileDestination, responseSerializer : Serializer) -> DownloadAPIRequest<Model,ErrorModel>
        where Serializer.SerializedObject == Model, Serializer.SerializedError == ErrorModel
    {
        return DownloadAPIRequest(type: .download(destination), path: path, tron: self, responseSerializer: responseSerializer)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.DownloadResuming.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination to download to.
     
     - parameter resumingFrom: Resume data for current request.
     
     - parameter responseSerializer: object used to serialize response.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    open func download<Model, ErrorModel, Serializer: ErrorHandlingDownloadResponseSerializerProtocol>
        (_ path: String, to destination: @escaping DownloadRequest.DownloadFileDestination, resumingFrom: Data, responseSerializer : Serializer) -> DownloadAPIRequest<Model,ErrorModel>
        where Serializer.SerializedObject == Model, Serializer.SerializedError == ErrorModel
    {
        return DownloadAPIRequest(type: .downloadResuming(data: resumingFrom, destination: destination), path: path, tron: self, responseSerializer: responseSerializer)
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
}
