//
//  SwiftyJSONDecodable.swift
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
import TRON

// swiftlint:disable multiple_closure_params

/**
 Protocol for creating model from SwiftyJSON object.
 */
public protocol JSONDecodable {
    /// Creates model object from SwiftyJSON.JSON struct.
    init(json: JSON) throws
}

/// `JSONDecodable` data response parser
open class JSONDecodableParser<Model: JSONDecodable>: DataResponseSerializerProtocol {

    /// Reading options to be used when reading JSON from Data, using JSONSerialization.
    public let options: JSONSerialization.ReadingOptions

    /// Defines how JSON should be preprocessed before passing to Model initializer.
    public let traverseJSON: (JSON) -> JSON

    /// Creates `JSONDecodableParser` with `options`.
    public init(options: JSONSerialization.ReadingOptions, traversingJSON: @escaping (JSON) -> JSON = { $0 }) {
        self.options = options
        self.traverseJSON = traversingJSON
    }

    /// Method used by response handlers that takes a request, response, data and error and returns a result.
    open func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Model {
        if let error = error {
            throw error
        }
        if let type = Model.self as? EmptyResponse.Type, let emptyValue = type.emptyValue() as? Model {
            return emptyValue
        }
        let json = try JSON(data: data ?? Data(), options: options)
        return try Model(json: traverseJSON(json))
    }
}

extension JSON: JSONDecodable {
    /// Creates JSON from JSON container.
    public init(json: JSON) throws {
        if let array = json.array { self.init(array) } else if let dictionary = json.dictionary { self.init(dictionary) } else { self.init(json.rawValue) }
    }
}

/// Serializer for objects, that conform to `JSONDecodable` protocol.
open class JSONDecodableSerializer {
    /// `TRON` instance to be used to send requests
    let tron: TRON

    /// Reading options to use while calling `JSONSerialization.jsonObject(withData:options:)`
    open var options: JSONSerialization.ReadingOptions

    /// Defines how JSON should be preprocessed before passing to Model initializer.
    open var traverseJSON: (JSON) -> JSON

    /// Creates `JSONDecodableSerializer` with `tron` instance to send requests, and JSON reading `options` to be passed to `JSONSerialization`.
    public init(tron: TRON, options: JSONSerialization.ReadingOptions = [], traversingJSON: @escaping (JSON) -> JSON = { $0 }) {
        self.tron = tron
        self.options = options
        self.traverseJSON = traversingJSON
    }

    /**
     Creates APIRequest with specified relative path and type RequestType.Default.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - returns: APIRequest instance.
     */
    open func request<Model: JSONDecodable, ErrorModel: ErrorSerializable>(_ path: String) -> APIRequest<Model, ErrorModel> {
        return tron.request(path, responseSerializer: JSONDecodableParser(options: options, traversingJSON: traverseJSON))
    }

    /**
     Creates APIRequest with specified relative path and type RequestType.UploadFromFile.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter fileURL: File url to upload from.
     
     - returns: APIRequest instance.
     */
    open func upload<Model: JSONDecodable, ErrorModel: ErrorSerializable>(_ path: String, fromFileAt fileURL: URL) -> UploadAPIRequest<Model, ErrorModel> {
        return tron.upload(path, fromFileAt: fileURL, responseSerializer: JSONDecodableParser(options: options, traversingJSON: traverseJSON))
    }

    /**
     Creates APIRequest with specified relative path and type RequestType.UploadData.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter data: Data to upload.
     
     - returns: APIRequest instance.
     */
    open func upload<Model: JSONDecodable, ErrorModel: ErrorSerializable>(_ path: String, data: Data) -> UploadAPIRequest<Model, ErrorModel> {
        return tron.upload(path, data: data, responseSerializer: JSONDecodableParser(options: options, traversingJSON: traverseJSON))
    }

    /**
     Creates APIRequest with specified relative path and type RequestType.UploadStream.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter stream: Stream to upload from.
     
     - returns: APIRequest instance.
     */
    open func upload<Model: JSONDecodable, ErrorModel: ErrorSerializable>(_ path: String, from stream: InputStream) -> UploadAPIRequest<Model, ErrorModel> {
        return tron.upload(path, from: stream, responseSerializer: JSONDecodableParser(options: options, traversingJSON: traverseJSON))
    }

    /**
     Creates MultipartAPIRequest with specified relative path.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter formData: Multipart form data creation block.
     
     - returns: MultipartAPIRequest instance.
     */
    open func uploadMultipart<Model: JSONDecodable, ErrorModel: ErrorSerializable>(_ path: String,
                                                                                   encodingMemoryThreshold: UInt64 = MultipartFormData.encodingMemoryThreshold,
                                                                                   fileManager: FileManager = .default,
                                                                                   formData: @escaping (MultipartFormData) -> Void) -> UploadAPIRequest<Model, ErrorModel> {
        return tron.uploadMultipart(path,
                                    responseSerializer: JSONDecodableParser(options: options,
                                                                            traversingJSON: traverseJSON),
                                    encodingMemoryThreshold: encodingMemoryThreshold,
                                    fileManager: fileManager,
                                    formData: formData)
    }
}

extension TRON {
    /// Creates `JSONDecodableSerializer` with current `TRON` instance.
    open var swiftyJSON: JSONDecodableSerializer {
        return JSONDecodableSerializer(tron: self)
    }

    /// Creates `CodableSerializer` with current `TRON` instance and specific `options` for `JSONSerialization`.
    /// `traversingJSON` closure defines how JSON should be preprocessed before passing to Model initializer.
    open func swiftyJSON(readingOptions options: JSONSerialization.ReadingOptions = [],
                         traversingJSON: @escaping (JSON) -> JSON = { $0 }) -> JSONDecodableSerializer {
        return JSONDecodableSerializer(tron: self, options: options, traversingJSON: traversingJSON)
    }
}

extension String: JSONDecodable {
    /// Creates String from JSON container
    public init(json: JSON) {
        self.init(json.stringValue)
    }
}

extension Int: JSONDecodable {

    /// Creates Int from JSON container
    public init(json: JSON) {
        self.init(json.intValue)
    }
}

extension Int8: JSONDecodable {

    /// Creates Int8 from JSON container
    public init(json: JSON) {
        self.init(json.int8Value)
    }
}

extension Int16: JSONDecodable {

    /// Creates Int16 from JSON container
    public init(json: JSON) {
        self.init(json.int16Value)
    }
}

extension Int32: JSONDecodable {

    /// Creates Int32 from JSON container
    public init(json: JSON) {
        self.init(json.int32Value)
    }
}

extension Int64: JSONDecodable {

    /// Creates Int64 from JSON container
    public init(json: JSON) {
        self.init(json.int64Value)
    }
}

extension UInt: JSONDecodable {

    /// Creates UInt from JSON container
    public init(json: JSON) {
        self.init(json.uIntValue)
    }
}

extension UInt8: JSONDecodable {

    /// Creates UInt8 from JSON container
    public init(json: JSON) {
        self.init(json.uInt8Value)
    }
}

extension UInt16: JSONDecodable {

    /// Creates UInt16 from JSON container
    public init(json: JSON) {
        self.init(json.uInt16Value)
    }
}

extension UInt32: JSONDecodable {

    /// Creates UInt32 from JSON container
    public init(json: JSON) {
        self.init(json.uInt32Value)
    }
}

extension UInt64: JSONDecodable {

    /// Creates UInt64 from JSON container
    public init(json: JSON) {
        self.init(json.uInt64Value)
    }
}

extension Float: JSONDecodable {
    /// Creates Float from JSON container
    public init(json: JSON) {
        self.init(json.floatValue)
    }
}

extension Double: JSONDecodable {
    /// Creates Double from JSON container
    public init(json: JSON) {
        self.init(json.doubleValue)
    }
}

extension Bool: JSONDecodable {
    /// Creates Bool from JSON container
    public init(json: JSON) {
        self.init(json.boolValue)
    }
}

extension Empty: JSONDecodable {
    /// Creates EmptyResponse from JSON container
    public init(json: JSON) {
        self = Empty.value
    }
}
