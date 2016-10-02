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
public struct JSONDecodableParser<Model: JSONDecodable, ErrorModel: JSONDecodable> : ErrorHandlingDataResponseSerializerProtocol
{
    public typealias SerializedError = ErrorModel
    
    public init() {}
    
    /// A closure used by response handlers that takes a request, response, data and error and returns a result.
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<Model> {
        return { request, response, data, error in
            let json = JSON(data: data ?? Data())
            do {
                let model = try Model.init(json: json)
                return Result.success(model)
            }
            catch {
                return .failure(error)
            }
        }
    }
}

extension ErrorHandlingDataResponseSerializerProtocol where SerializedError : JSONDecodable
{
    /// A closure used by response handlers that takes a parsed result, request, response, data and error and returns a serialized error.
    public var serializeError: (Result<SerializedObject>?,URLRequest?, HTTPURLResponse?, Data?, Error?) -> APIError<SerializedError> {
        return { erroredResponse, request, response, data, error in
            let serializationError : Error? = erroredResponse?.error ?? error
            var error = APIError<SerializedError>(request: request, response: response,data: data, error: serializationError)
            error.errorModel = try? SerializedError.init(json: JSON(data: data ?? Data()))
            return error
        }
    }
}

/// Error that is thrown, if after successful download, passed URL or Data with contents of that URL are nil.
public enum JSONDecodableDownloadSerializationError : Error {
    case failedToCreateJSONResponse
}

/// `JSONDecodable` download response parser
public struct JSONDecodableDownloadParser<Model: JSONDecodable, ErrorModel: JSONDecodable> : ErrorHandlingDownloadResponseSerializerProtocol
{
    public typealias SerializedError = ErrorModel
    
    public init() {}
    
    /// A closure used by response handlers that takes a request, response, url and error and returns a result.
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, URL?, Error?) -> Result<Model> {
        return { request, response, url, error in
            if let url = url, let data = try? Data(contentsOf: url) {
                let json = JSON(data: data)
                do {
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
}

extension ErrorHandlingDownloadResponseSerializerProtocol where SerializedError : JSONDecodable
{
    /// A closure used by response handlers that takes a parsed result, request, response, url and error and returns a serialized error.
    public var serializeError: (Result<SerializedObject>?,URLRequest?, HTTPURLResponse?, URL?, Error?) -> APIError<SerializedError> {
        return { erroredResponse, request, response, url, error in
            let serializationError : Error? = erroredResponse?.error ?? error
            var data : Data?
            if let url = url {
                data = try? Data(contentsOf: url)
            }
            var error = APIError<SerializedError>(request: request, response: response,data: data, error: serializationError)
            error.errorModel = try? SerializedError.init(json: JSON(data: data ?? Data()))
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

extension TRON {
    
    /**
     Creates APIRequest with specified relative path and type RequestType.Default.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - returns: APIRequest instance.
     */
    open func request<Model: JSONDecodable, ErrorModel:JSONDecodable>(_ path: String) -> APIRequest<Model,ErrorModel>
    {
        return APIRequest(path: path, tron: self, responseSerializer: JSONDecodableParser())
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadFromFile.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter fileURL: File url to upload from.
     
     - returns: APIRequest instance.
     */
    open func upload<Model:JSONDecodable, ErrorModel:JSONDecodable>(_ path: String, fromFileAt fileURL: URL) -> UploadAPIRequest<Model,ErrorModel> {
        return UploadAPIRequest(type: .uploadFromFile(fileURL), path: path, tron: self, responseSerializer: JSONDecodableParser())
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadData.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter data: Data to upload.
     
     - returns: APIRequest instance.
     */
    open func upload<Model:JSONDecodable, ErrorModel:JSONDecodable>(_ path: String, data: Data) -> UploadAPIRequest<Model,ErrorModel> {
        return UploadAPIRequest(type: .uploadData(data), path: path, tron: self, responseSerializer: JSONDecodableParser())
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadStream.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter stream: Stream to upload from.
     
     - returns: APIRequest instance.
     */
    open func upload<Model:JSONDecodable, ErrorModel:JSONDecodable>(_ path: String, from stream: InputStream) -> UploadAPIRequest<Model,ErrorModel> {
        return UploadAPIRequest(type: .uploadStream(stream), path: path, tron: self, responseSerializer: JSONDecodableParser())
    }
    
    /**
     Creates MultipartAPIRequest with specified relative path.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter formData: Multipart form data creation block.
     
     - returns: MultipartAPIRequest instance.
     */
    open func uploadMultipart<Model:JSONDecodable, ErrorModel:JSONDecodable>(_ path: String,
                              formData: @escaping (MultipartFormData) -> Void) -> UploadAPIRequest<Model,ErrorModel> {
        return UploadAPIRequest(type: .multipartFormData(formData), path: path, tron: self, responseSerializer: JSONDecodableParser())
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.Download.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination for downloading.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    open func download<Model: JSONDecodable, ErrorModel:JSONDecodable>(_ path: String, to destination: @escaping DownloadRequest.DownloadFileDestination) -> DownloadAPIRequest<Model, ErrorModel> {
        return DownloadAPIRequest(type: .download(destination), path: path, tron: self, responseSerializer: JSONDecodableDownloadParser())
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.DownloadResuming.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination to download to.
     
     - parameter resumingFrom: Resume data for current request.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    open func download<Model: JSONDecodable,ErrorModel:JSONDecodable>(_ path: String, to destination: @escaping DownloadRequest.DownloadFileDestination, resumingFrom: Data) -> DownloadAPIRequest<Model, ErrorModel> {
        return DownloadAPIRequest(type: .downloadResuming(data: resumingFrom, destination: destination), path: path, tron: self, responseSerializer: JSONDecodableDownloadParser())
    }
}

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
        self.init(json.stringValue)!
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
