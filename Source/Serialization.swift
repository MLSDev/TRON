//
//  ResponseBuilder.swift
//  TRON
//
//  Created by Denys Telezhkin on 11.12.15.
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

/// The type in which all data and upload response serializers must conform to in order to serialize a response.
public protocol ErrorHandlingDataResponseSerializerProtocol: DataResponseSerializerProtocol {
    /// The type of serialized object to be created by this `ErrorHandlingDataResponseSerializerProtocol`.
    associatedtype SerializedError

    /// A closure used by response handlers that takes a parsed result, request, response, data and error and returns a serialized error.
    var serializeError: (Alamofire.Result<SerializedObject>?, URLRequest?, HTTPURLResponse?, Data?, Error?) -> APIError<SerializedError> { get }
}

/// The type in which all download response serializers must conform to in order to serialize a response.
public protocol ErrorHandlingDownloadResponseSerializerProtocol: DownloadResponseSerializerProtocol {
    /// The type of serialized object to be created by this `ErrorHandlingDownloadResponseSerializerProtocol`.
    associatedtype SerializedError

    /// A closure used by response handlers that takes a parsed result, request, response, url and error and returns a serialized error.
    var serializeError: (Alamofire.Result<SerializedObject>?, URLRequest?, HTTPURLResponse?, URL?, Error?) -> APIError<SerializedError> { get }
}
