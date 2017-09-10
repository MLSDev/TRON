//
//  TRONCodable.swift
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
import Alamofire

#if swift (>=4.0)

public struct CodableParser<Model: Codable, ErrorModel: Codable> : ErrorHandlingDataResponseSerializerProtocol {
        
    public typealias SerializedError = ErrorModel
    
    public init() {}
    
    /// A closure used by response handlers that takes a request, response, data and error and returns a result.
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<Model> {
        return { request, response, data, error in
            do {
                let model = try JSONDecoder().decode(Model.self, from: data ?? Data())
                return Result.success(model)
            }
            catch {
                return .failure(error)
            }
        }
    }
}

extension ErrorHandlingDataResponseSerializerProtocol where SerializedError: Codable {
    /// A closure used by response handlers that takes a parsed result, request, response, data and error and returns a serialized error.
    public var serializeError: (Result<SerializedObject>?,URLRequest?, HTTPURLResponse?, Data?, Error?) -> APIError<SerializedError> {
        return { erroredResponse, request, response, data, error in
            let serializationError : Error? = erroredResponse?.error ?? error
            var error = APIError<SerializedError>(request: request, response: response,data: data, error: serializationError)
            error.errorModel = try? JSONDecoder().decode(SerializedError.self, from: data ?? Data())
            return error
        }
    }
}
    
/// Error that is thrown, if after successful download, passed URL or Data with contents of that URL are nil.
public enum CodableDownloadSerializationError : Error {
    case failedToCreateJSONResponse
}
    
/// `JSONDecodable` download response parser
public struct CodableDownloadParser<Model: Codable, ErrorModel: Codable> : ErrorHandlingDownloadResponseSerializerProtocol
{
    public typealias SerializedError = ErrorModel
    
    public init() {}
    
    /// A closure used by response handlers that takes a request, response, url and error and returns a result.
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, URL?, Error?) -> Result<Model> {
        return { request, response, url, error in
            if let url = url, let data = try? Data(contentsOf: url) {
                do {
                    let model = try JSONDecoder().decode(Model.self, from: data)
                    return Result.success(model)
                }
                catch {
                    return .failure(error)
                }
            }
            return .failure(CodableDownloadSerializationError.failedToCreateJSONResponse)
        }
    }
}
    
extension ErrorHandlingDownloadResponseSerializerProtocol where SerializedError : Codable
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
            error.errorModel = try? JSONDecoder().decode(SerializedError.self, from: data ?? Data())
            return error
        }
    }
}
    
public struct CodableSerializer {
    let tron: TRON
    
    init(_ tron: TRON) {
        self.tron = tron
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.Default.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - returns: APIRequest instance.
     */
    public func request<Model: Codable, ErrorModel:Codable>(_ path: String) -> APIRequest<Model,ErrorModel>
    {
        return tron.request(path, responseSerializer: CodableParser())
    }
    
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadFromFile.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter fileURL: File url to upload from.
     
     - returns: APIRequest instance.
     */
    public func upload<Model:Codable, ErrorModel:Codable>(_ path: String, fromFileAt fileURL: URL) -> UploadAPIRequest<Model,ErrorModel>
    {
        return tron.upload(path, fromFileAt: fileURL, responseSerializer: CodableParser())
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadData.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter data: Data to upload.
     
     - returns: APIRequest instance.
     */
    public func upload<Model:Codable, ErrorModel:Codable>(_ path: String, data: Data) -> UploadAPIRequest<Model,ErrorModel>
    {
        return tron.upload(path, data: data, responseSerializer: CodableParser())
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadStream.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter stream: Stream to upload from.
     
     - returns: APIRequest instance.
     */
    public func upload<Model:Codable, ErrorModel:Codable>(_ path: String, from stream: InputStream) -> UploadAPIRequest<Model,ErrorModel>
    {
        return tron.upload(path, from: stream, responseSerializer: CodableParser())
    }
    
    /**
     Creates MultipartAPIRequest with specified relative path.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter formData: Multipart form data creation block.
     
     - returns: MultipartAPIRequest instance.
     */
    public func uploadMultipart<Model:Codable, ErrorModel:Codable>(_ path: String,
                                                                   formData: @escaping (MultipartFormData) -> Void) -> UploadAPIRequest<Model,ErrorModel>
    {
        return tron.uploadMultipart(path,
                                    responseSerializer: CodableParser(),
                                    formData: formData)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.Download.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination for downloading.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    public func download<Model:Codable, ErrorModel:Codable>(_ path: String, to destination: @escaping DownloadRequest.DownloadFileDestination) -> DownloadAPIRequest<Model, ErrorModel>
    {
        return tron.download(path,
                             to: destination,
                             responseSerializer: CodableDownloadParser())
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.DownloadResuming.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination to download to.
     
     - parameter resumingFrom: Resume data for current request.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    public func download<Model:Codable,ErrorModel:Codable>(_ path: String, to destination: @escaping DownloadRequest.DownloadFileDestination, resumingFrom: Data) -> DownloadAPIRequest<Model, ErrorModel>
    {
        return tron.download(path, to: destination, resumingFrom: resumingFrom, responseSerializer: CodableDownloadParser())
    }
}
    
extension TRON {
    open var codable : CodableSerializer {
        return CodableSerializer(self)
    }
}
    
#endif
