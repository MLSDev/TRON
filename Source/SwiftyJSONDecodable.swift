//
//  SwiftyJSONBuilder.swift
//  TRON
//
//  Created by Denys Telezhkin on 06.02.16.
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
import SwiftyJSON
import Alamofire

/**
 Protocol for creating model from SwiftyJSON object.
 */
public protocol JSONDecodable  {
    
    /// Creates model object from SwiftyJSON.JSON struct.
    init(json: JSON) throws
}

/// `JSONDecodable` data response parser
open class JSONDecodableParser<Model: JSONDecodable, ErrorModel: JSONDecodable> : ErrorHandlingDataResponseSerializerProtocol
{
    public typealias SerializedError = ErrorModel
    
    public let options: JSONSerialization.ReadingOptions
    
    public init(options: JSONSerialization.ReadingOptions) {
        self.options = options
    }
    
    /// A closure used by response handlers that takes a request, response, data and error and returns a result.
    open var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<Model> {
        return { [weak self] request, response, data, error in
            do {
                let data = data ?? Data()
                let json = (try? JSON(data: data, options: self?.options ?? [])) ?? JSON.null
                let model = try Model.init(json: json)
                return Result.success(model)
            }
            catch {
                return .failure(error)
            }
        }
    }
    
    /// A closure used by response handlers that takes a parsed result, request, response, data and error and returns a serialized error.
    open var serializeError: (Result<SerializedObject>?,URLRequest?, HTTPURLResponse?, Data?, Error?) -> APIError<SerializedError> {
        return { [weak self] erroredResponse, request, response, data, error in
            let serializationError : Error? = erroredResponse?.error ?? error
            var error = APIError<SerializedError>(request: request, response: response,data: data, error: serializationError)
            let data = data ?? Data()
            let json = (try? JSON(data: data, options: self?.options ?? [])) ?? JSON.null
            error.errorModel = try? SerializedError.init(json: json)
            return error
        }
    }
}

/// Error that is thrown, if after successful download, passed URL or Data with contents of that URL are nil.
public enum JSONDecodableDownloadSerializationError : Error {
    case failedToCreateJSONResponse
}

/// `JSONDecodable` download response parser
open class JSONDecodableDownloadParser<Model: JSONDecodable, ErrorModel: JSONDecodable> : ErrorHandlingDownloadResponseSerializerProtocol
{
    public typealias SerializedError = ErrorModel
    
    public let options: JSONSerialization.ReadingOptions
    
    public init(options: JSONSerialization.ReadingOptions) {
        self.options = options
    }
    
    /// A closure used by response handlers that takes a request, response, url and error and returns a result.
    open var serializeResponse: (URLRequest?, HTTPURLResponse?, URL?, Error?) -> Result<Model> {
        return { [weak self] request, response, url, error in
            if let url = url, let data = try? Data(contentsOf: url) {
                do {
                    let json = (try? JSON(data: data, options: self?.options ?? [])) ?? JSON.null
                    let model = try Model.init(json: json)
                    return Result.success(model)
                }
                catch {
                    return .failure(error)
                }
            }
            return .failure(JSONDecodableDownloadSerializationError.failedToCreateJSONResponse)
        }
    }
    
    /// A closure used by response handlers that takes a parsed result, request, response, url and error and returns a serialized error.
    open var serializeError: (Result<SerializedObject>?,URLRequest?, HTTPURLResponse?, URL?, Error?) -> APIError<SerializedError> {
        return { [weak self] erroredResponse, request, response, url, error in
            let serializationError : Error? = erroredResponse?.error ?? error
            var data : Data?
            if let url = url {
                data = try? Data(contentsOf: url)
            }
            var error = APIError<SerializedError>(request: request, response: response,data: data, error: serializationError)
            let json: JSON = (try? JSON(data: data ?? Data(), options: self?.options ?? [])) ?? JSON.null
            error.errorModel = try? SerializedError.init(json: json)
            return error
        }
    }
}

extension JSON : JSONDecodable {
    public init(json: JSON) throws {
        if let array = json.array { self.init(array) }
        else if let dictionary = json.dictionary { self.init(dictionary) }
        else { self.init(json.rawValue) }
    }
}

// Serializer for objects, that conform to `JSONDecodable` protocol.
open class JSONDecodableSerializer
{
    // `TRON` instance to be used to send requests
    let tron: TRON
    
    // Reading options to use while calling `JSONSerialization.jsonObject(withData:options:)`
    open var options : JSONSerialization.ReadingOptions
    
    // Creates `JSONDecodableSerializer` with `tron` instance to send requests, and JSON reading `options` to be passed to `JSONSerialization`.
    public init(tron: TRON, options: JSONSerialization.ReadingOptions = []) {
        self.tron = tron
        self.options = options
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.Default.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - returns: APIRequest instance.
     */
    open func request<Model:JSONDecodable,ErrorModel:JSONDecodable>(_ path: String) -> APIRequest<Model,ErrorModel>
    {
        return tron.request(path, responseSerializer: JSONDecodableParser(options: options))
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadFromFile.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter fileURL: File url to upload from.
     
     - returns: APIRequest instance.
     */
    open func upload<Model:JSONDecodable, ErrorModel:JSONDecodable>(_ path: String, fromFileAt fileURL: URL) -> UploadAPIRequest<Model,ErrorModel>
    {
        return tron.upload(path, fromFileAt: fileURL, responseSerializer: JSONDecodableParser(options: options))
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadData.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter data: Data to upload.
     
     - returns: APIRequest instance.
     */
    open func upload<Model:JSONDecodable, ErrorModel:JSONDecodable>(_ path: String, data: Data) -> UploadAPIRequest<Model,ErrorModel>
    {
        return tron.upload(path, data: data, responseSerializer: JSONDecodableParser(options: options))
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadStream.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter stream: Stream to upload from.
     
     - returns: APIRequest instance.
     */
    open func upload<Model:JSONDecodable, ErrorModel:JSONDecodable>(_ path: String, from stream: InputStream) -> UploadAPIRequest<Model,ErrorModel>
    {
        return tron.upload(path, from: stream, responseSerializer: JSONDecodableParser(options: options))
    }
    
    /**
     Creates MultipartAPIRequest with specified relative path.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter formData: Multipart form data creation block.
     
     - returns: MultipartAPIRequest instance.
     */
    open func uploadMultipart<Model:JSONDecodable, ErrorModel:JSONDecodable>(_ path: String,
                                                   formData: @escaping (MultipartFormData) -> Void) -> UploadAPIRequest<Model,ErrorModel>
    {
        return tron.uploadMultipart(path,
                                    responseSerializer: JSONDecodableParser(options: options),
                                    formData: formData)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.Download.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination for downloading.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    open func download<Model:JSONDecodable, ErrorModel:JSONDecodable>(_ path: String, to destination: @escaping DownloadRequest.DownloadFileDestination) -> DownloadAPIRequest<Model, ErrorModel>
    {
        return tron.download(path,
                             to: destination,
                             responseSerializer: JSONDecodableDownloadParser(options: options))
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.DownloadResuming.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination to download to.
     
     - parameter resumingFrom: Resume data for current request.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    open func download<Model:JSONDecodable,ErrorModel:JSONDecodable>(_ path: String, to destination: @escaping DownloadRequest.DownloadFileDestination, resumingFrom: Data) -> DownloadAPIRequest<Model, ErrorModel>
    {
        return tron.download(path, to: destination, resumingFrom: resumingFrom, responseSerializer: JSONDecodableDownloadParser(options: options))
    }
}

extension TRON {
    // Creates `JSONDecodableSerializer` with current `TRON` instance.
    open var swiftyJSON : JSONDecodableSerializer {
        return JSONDecodableSerializer(tron: self)
    }
    
    // Creates `CodableSerializer` with current `TRON` instance and specific `options` for `JSONSerialization`.
    open func swiftyJSON(readingOptions options: JSONSerialization.ReadingOptions) -> JSONDecodableSerializer {
        return JSONDecodableSerializer(tron: self, options: options)
    }
}

// This approach is bad, because it allows any JSONDecodable.Type to be created, not just specific one.
// See https://github.com/MLSDev/TRON/issues/17 for details

//extension Array : JSONDecodable {
//    public init(json: JSON) {
//        self.init(json.arrayValue.flatMap {
//            if let type = Element.self as? JSONDecodable.Type {
//                let element : Element?
//                do {
//                    element = try type.init(json: $0) as? Element
//                } catch {
//                    return nil
//                }
//                return element
//            }
//            return nil
//        })
//    }
//}

extension String : JSONDecodable  {
    public init(json: JSON) {
        #if swift(>=4)
            self.init(json.stringValue)
        #else
            self.init(json.stringValue)!
        #endif
    }
}

extension Int : JSONDecodable  {
    public init(json: JSON) {
        self.init(json.intValue)
    }
}

extension Float : JSONDecodable {
    public init(json: JSON) {
        self.init(json.floatValue)
    }
}

extension Double : JSONDecodable {
    public init(json: JSON) {
        self.init(json.doubleValue)
    }
}

extension Bool : JSONDecodable {
    public init(json: JSON) {
        self.init(json.boolValue)
    }
}

extension EmptyResponse : JSONDecodable {
    public init(json: JSON) throws {}
}
