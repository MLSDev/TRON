//
//  BaseRequest.swift
//  TRON
//
//  Created by Denys Telezhkin on 15.05.16.
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
 Protocol, that defines how URL is constructed by consumer.
 */
public protocol URLBuildable {

    /**
     Construct URL with given path
     
     - parameter path: relative path
     
     - returns constructed URL
     */
    func url(forPath path: String) -> URL
}

/// Protocol used to allow `APIRequest` to communicate with `TRON` instance.
public protocol TronDelegate: class {

    /// Alamofire.Manager used to send requests
    var session: Alamofire.Session { get }

    /// Global array of plugins on `TRON` instance
    var plugins: [Plugin] { get }
}

/// Base class, that contains common functionality, extracted from `APIRequest` and `MultipartAPIRequest`.
open class BaseRequest<Model, ErrorModel> {

    /// Serializes Data into Model
    public typealias ResponseParser = (_ request: URLRequest?, _ response: HTTPURLResponse?, _ data: Data?, _ error: Error?) throws -> Model

    /// Serializes received failed response into APIError<ErrorModel> object
    public typealias ErrorParser = (_ request: URLRequest?, _ response: HTTPURLResponse?, _ data: Data?, _ error: Error?) -> ErrorModel

    /// Relative path of current request
    public let path: String

    /// HTTP method
    open var method: Alamofire.HTTPMethod = .get

    /// Parameters of current request.
    open var parameters: [String: Any] = [:]

    /// Defines how parameters are encoded.
    open var parameterEncoding: Alamofire.ParameterEncoding

    /// Headers, that should be used for current request.
    /// - Note: Resulting headers may include global headers from `TRON` instance and `Alamofire.Manager` defaultHTTPHeaders.
    open var headers: HTTPHeaders = .init()

    /// URL builder for current request
    open var urlBuilder: URLBuildable

    /// API stub to be used when stubbing this request
    open var apiStub: APIStub? {
        didSet {
            apiStub?.isEnabled = (tronDelegate as? TRON)?.stubbingEnabled ?? false
        }
    }

    /// Queue, used to deliver result completion blocks. Defaults to TRON.resultDeliveryQueue queue.
    open var resultDeliveryQueue: DispatchQueue

    /// Delegate property that is used to communicate with `TRON` instance.
    weak var tronDelegate: TronDelegate?

    /// Array of plugins for current `APIRequest`.
    open var plugins: [Plugin] = []

    internal var allPlugins: [Plugin] {
        return plugins + (tronDelegate?.plugins ?? [])
    }

    /// Creates `BaseRequest` instance, initialized with several `TRON` properties.
    public init(path: String, tron: TRON) {
        self.path = path
        self.tronDelegate = tron
        self.urlBuilder = tron.urlBuilder
        self.resultDeliveryQueue = tron.resultDeliveryQueue
        self.parameterEncoding = tron.parameterEncoding
    }

    internal func alamofireRequest(from manager: Alamofire.Session) -> Alamofire.Request {
        fatalError("Needs to be implemented in subclasses")
    }

    internal func callSuccessFailureBlocks(_ success: ((Model) -> Void)?,
                                           failure: ((ErrorModel) -> Void)?,
                                           response: Alamofire.DataResponse<Model>) {
        switch response.result {
        case .success(let value):
            resultDeliveryQueue.async {
                success?(value)
            }
        case .failure(let error):
            resultDeliveryQueue.async {
                guard let error = error as? ErrorModel else {
                    return
                }
                failure?(error)
            }
        }
    }

    internal func willSendRequest() {
        allPlugins.forEach { plugin in
            plugin.willSendRequest(self)
        }
    }

    internal func willSendAlamofireRequest(_ request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.willSendAlamofireRequest(request, formedFrom: self)
        }
    }

    internal func didSendAlamofireRequest(_ request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.didSendAlamofireRequest(request, formedFrom: self)
        }
    }

    internal func willProcessResponse(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?), for request: Request) {
        allPlugins.forEach { plugin in
            plugin.willProcessResponse(response: response, forRequest: request, formedFrom: self)
        }
    }

    internal func didSuccessfullyParseResponse(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?), creating result: Model, forRequest request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.didSuccessfullyParseResponse(response, creating: result, forRequest: request, formedFrom: self)
        }
    }

    internal func didReceiveDataResponse(_ response: DataResponse<Model>, forRequest request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.didReceiveDataResponse(response, forRequest: request, formedFrom: self)
        }
    }
}
