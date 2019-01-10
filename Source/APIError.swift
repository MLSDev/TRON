//
//  APIError.swift
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

public protocol ErrorSerializable: Error {
    associatedtype SerializedObject

    init?(serializedObject: SerializedObject?, request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?)
}

public protocol DownloadErrorSerializable: Error {
    associatedtype SerializedObject

    init?(serializedObject: SerializedObject?, request: URLRequest?, response: HTTPURLResponse?, fileURL: URL?, error: Error?)
}

/// `APIError<T>` is used as a generic wrapper for all kinds of APIErrors.
open class APIError<T> : Error, LocalizedError, ErrorSerializable, DownloadErrorSerializable {

    /// URLRequest that was unsuccessful
    public let request: URLRequest?

    /// Response received from web service
    public let response: HTTPURLResponse?

    /// Data, contained in response. Nil, if this error is coming from a download request.
    public let data: Data?

    /// Downloaded fileURL. Nil, if used with upload or data requests.
    public let fileURL: URL?

    /// Error instance, created by Foundation Loading System or Alamofire.
    public let error: Error?

    public let serializedObject: T?

    required public init?(serializedObject: T?, request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) {
        guard let receivedError = error else { return nil }
        self.serializedObject = serializedObject
        self.request = request
        self.response = response
        self.data = data
        self.error = receivedError
        fileURL = nil
    }

    required public init?(serializedObject: T?, request: URLRequest?, response: HTTPURLResponse?, fileURL: URL?, error: Error?) {
        guard let receivedError = error else { return nil }
        self.serializedObject = serializedObject
        self.request = request
        self.response = response
        self.error = receivedError
        self.fileURL = fileURL
        data = nil
    }

    /// Prints localized description of error inside
    public var errorDescription: String? {
        return error?.localizedDescription
    }
}
