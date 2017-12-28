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

open class CodableParser<Model: Decodable, ErrorModel: Decodable> : ErrorHandlingDataResponseSerializerProtocol {
        
    public typealias SerializedError = ErrorModel
    
    public let modelDecoder: JSONDecoder
    public let errorDecoder: JSONDecoder
    
    public init(modelDecoder: JSONDecoder, errorDecoder: JSONDecoder) {
        self.modelDecoder = modelDecoder
        self.errorDecoder = errorDecoder
    }
    
    /// A closure used by response handlers that takes a request, response, data and error and returns a result.
    open var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<Model> {
        return { [weak self] request, response, data, error in
            do {
                let model = try (self?.modelDecoder ?? JSONDecoder()).decode(Model.self, from: data ?? Data())
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
            error.errorModel = try? (self?.errorDecoder ?? JSONDecoder()).decode(SerializedError.self, from: data ?? Data())
            return error
        }
    }
}
    
/// Error that is thrown, if after successful download, passed URL or Data with contents of that URL are nil.
public enum CodableDownloadSerializationError : Error {
    case failedToCreateJSONResponse
}
    
/// `JSONDecodable` download response parser
open class CodableDownloadParser<Model: Decodable, ErrorModel: Decodable> : ErrorHandlingDownloadResponseSerializerProtocol
{
    public typealias SerializedError = ErrorModel
    
    // Decoder to be used when decoding `Model`.
    public let modelDecoder: JSONDecoder
    
    // Decoder to be used when decoding `ErrorModel`.
    public let errorDecoder: JSONDecoder
    
    // Creates parser with `modelDecoder` and `errorDecoder`.
    public init(modelDecoder: JSONDecoder, errorDecoder: JSONDecoder) {
        self.modelDecoder = modelDecoder
        self.errorDecoder = errorDecoder
    }
    
    /// A closure used by response handlers that takes a request, response, url and error and returns a result.
    open var serializeResponse: (URLRequest?, HTTPURLResponse?, URL?, Error?) -> Result<Model> {
        return { [weak self] request, response, url, error in
            if let url = url, let data = try? Data(contentsOf: url) {
                do {
                    let model = try (self?.modelDecoder ?? JSONDecoder()).decode(Model.self, from: data)
                    return Result.success(model)
                }
                catch {
                    return .failure(error)
                }
            }
            return .failure(CodableDownloadSerializationError.failedToCreateJSONResponse)
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
            error.errorModel = try? (self?.errorDecoder ?? JSONDecoder()).decode(SerializedError.self, from: data ?? Data())
            return error
        }
    }
}
    
// Serializer for objects, that conform to `Decodable` protocol.
open class CodableSerializer {
    
    // `TRON` instance to be used to send requests
    let tron: TRON
    
    // Decoder to be used while parsing model.
    open let modelDecoder : JSONDecoder
    
    // Decoder to be used while parsing error.
    open let errorDecoder : JSONDecoder
    
    // Creates `CodableSerializer` with `tron` instance to send requests, and `decoder` to be used while parsing response.
    init(_ tron: TRON,
         modelDecoder: JSONDecoder = JSONDecoder(),
         errorDecoder: JSONDecoder = JSONDecoder())
    {
        self.tron = tron
        self.modelDecoder = modelDecoder
        self.errorDecoder = errorDecoder
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.Default.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - returns: APIRequest instance.
     */
    public func request<Model: Decodable, ErrorModel:Decodable>(_ path: String) -> APIRequest<Model,ErrorModel>
    {
        return tron.request(path,
                            responseSerializer: CodableParser(modelDecoder: modelDecoder,
                                                              errorDecoder: errorDecoder))
    }
    
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadFromFile.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter fileURL: File url to upload from.
     
     - returns: APIRequest instance.
     */
    public func upload<Model:Decodable, ErrorModel:Decodable>(_ path: String, fromFileAt fileURL: URL) -> UploadAPIRequest<Model,ErrorModel>
    {
        return tron.upload(path, fromFileAt: fileURL,
                           responseSerializer: CodableParser(modelDecoder: modelDecoder,
                                                             errorDecoder: errorDecoder))
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadData.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter data: Data to upload.
     
     - returns: APIRequest instance.
     */
    public func upload<Model:Decodable, ErrorModel:Decodable>(_ path: String, data: Data) -> UploadAPIRequest<Model,ErrorModel>
    {
        return tron.upload(path, data: data, responseSerializer: CodableParser(modelDecoder: modelDecoder,
                                                                               errorDecoder: errorDecoder))
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.UploadStream.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter stream: Stream to upload from.
     
     - returns: APIRequest instance.
     */
    public func upload<Model:Decodable, ErrorModel:Decodable>(_ path: String, from stream: InputStream) -> UploadAPIRequest<Model,ErrorModel>
    {
        return tron.upload(path, from: stream, responseSerializer: CodableParser(modelDecoder: modelDecoder,
                                                                                 errorDecoder: errorDecoder))
    }
    
    /**
     Creates MultipartAPIRequest with specified relative path.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter formData: Multipart form data creation block.
     
     - returns: MultipartAPIRequest instance.
     */
    public func uploadMultipart<Model:Decodable, ErrorModel:Decodable>(_ path: String,
                                                                   formData: @escaping (MultipartFormData) -> Void) -> UploadAPIRequest<Model,ErrorModel>
    {
        return tron.uploadMultipart(path,
                                    responseSerializer: CodableParser(modelDecoder: modelDecoder,
                                                                      errorDecoder: errorDecoder),
                                    formData: formData)
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.Download.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination for downloading.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    public func download<Model:Decodable, ErrorModel:Decodable>(_ path: String, to destination: @escaping DownloadRequest.DownloadFileDestination) -> DownloadAPIRequest<Model, ErrorModel>
    {
        return tron.download(path,
                             to: destination,
                             responseSerializer: CodableDownloadParser(modelDecoder: modelDecoder,
                                                                       errorDecoder: errorDecoder))
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.DownloadResuming.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter destination: Destination to download to.
     
     - parameter resumingFrom: Resume data for current request.
     
     - returns: APIRequest instance.
     
     - seealso: `Alamofire.Request.suggestedDownloadDestination(directory:domain:)` method.
     */
    public func download<Model:Decodable,ErrorModel:Decodable>(_ path: String, to destination: @escaping DownloadRequest.DownloadFileDestination, resumingFrom: Data) -> DownloadAPIRequest<Model, ErrorModel>
    {
        return tron.download(path, to: destination,
                             resumingFrom: resumingFrom,
                             responseSerializer: CodableDownloadParser(modelDecoder: modelDecoder,
                                                                       errorDecoder: errorDecoder))
    }
}
    
extension TRON {
    // Creates `CodableSerializer` with current `TRON` instance.
    open var codable : CodableSerializer {
        return CodableSerializer(self)
    }
    
    // Creates `CodableSerializer` with current `TRON` instance, specific `modelDecoder` and `errorDecoder`.
    // Note: `modelDecoder` and `errorDecoder` are allowed to be the same object.
    open func codable(modelDecoder: JSONDecoder, errorDecoder: JSONDecoder) -> CodableSerializer {
        return CodableSerializer(self, modelDecoder: modelDecoder, errorDecoder: errorDecoder)
    }
}
    
#endif
