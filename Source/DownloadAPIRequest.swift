//
//  DownloadAPIRequest.swift
//  TRON
//
//  Created by Denys Telezhkin on 11.09.16.
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

/// Types of `DownloadAPIRequest`.
public enum DownloadRequestType {
    /// Will create `NSURLSessionDownloadTask` using `downloadTaskWithRequest(_)` method
    case download(DownloadRequest.DownloadFileDestination)

    /// Will create `NSURLSessionDownloadTask` using `downloadTaskWithResumeData(_)` method
    case downloadResuming(data: Data, destination: DownloadRequest.DownloadFileDestination)
}

/**
 `DownloadAPIRequest` encapsulates download request creation logic, stubbing options, and response/error parsing.
 */
open class DownloadAPIRequest<Model, ErrorModel>: BaseRequest<Model, ErrorModel> {

    /// DownloadAPIREquest type
    let type: DownloadRequestType

    /// Serialize download response into `Result<Model>`.
    public typealias DownloadResponseParser = (_ request: URLRequest?, _ response: HTTPURLResponse?, _ url: URL?, _ error: Error?) -> Result<Model>

    /// Serializes received failed response into APIError<ErrorModel> object
    public typealias DownloadErrorParser = (Result<Model>?, _ request: URLRequest?, _ response: HTTPURLResponse?, _ url: URL?, _ error: Error?) -> APIError<ErrorModel>

    /// Serializes received response into Result<Model>
    open var responseParser: DownloadResponseParser

    /// Serializes received error into APIError<ErrorModel>
    open var errorParser: DownloadErrorParser

    /// Closure that is applied to request before it is sent.
    open var validationClosure: (DownloadRequest) -> DownloadRequest = { $0.validate() }

    /// Creates `DownloadAPIRequest` with specified `type`, `path` and configures it with to be used with `tron`.
    public init<Serializer: ErrorHandlingDownloadResponseSerializerProtocol>(type: DownloadRequestType, path: String, tron: TRON, responseSerializer: Serializer)
        where Serializer.SerializedObject == Model, Serializer.SerializedError == ErrorModel {
        self.type = type
        self.responseParser = { request, response, data, error in
            responseSerializer.serializeResponse(request, response, data, error)
        }
        self.errorParser = { result, request, response, data, error in
            return responseSerializer.serializeError(result, request, response, data, error)
        }
        super.init(path: path, tron: tron)
    }

    override func alamofireRequest(from manager: SessionManager) -> Request? {
        switch type {
        case .download(let destination):
            return manager.download(urlBuilder.url(forPath: path), method: method, parameters: parameters,
                                    encoding: parameterEncoding,
                                    headers: headerBuilder.headers(forAuthorizationRequirement: authorizationRequirement, including: headers),
                                    to: destination)

        case .downloadResuming(let data, let destination):
            return manager.download(resumingWith: data, to: destination)
        }
    }

    @discardableResult
    /**
     Perform current request with completion block, that contains Alamofire.Response.
     
     - parameter completion: Alamofire.Response completion block.
     
     - returns: Alamofire.Request or nil if request was stubbed.
     */
    open func performCollectingTimeline(withCompletion completion: @escaping ((Alamofire.DownloadResponse<Model>) -> Void)) -> DownloadRequest? {
        if performStub(completion: completion) {
            return nil
        }
        return performAlamofireRequest(completion)
    }

    private func performAlamofireRequest(_ completion : @escaping (DownloadResponse<Model>) -> Void) -> DownloadRequest {
        guard let manager = tronDelegate?.manager else {
            fatalError("Manager cannot be nil while performing APIRequest")
        }
        willSendRequest()
        guard let request = alamofireRequest(from: manager) as? DownloadRequest else {
            fatalError("Failed to receive DataRequest")
        }
        willSendAlamofireRequest(request)
        if !manager.startRequestsImmediately {
            request.resume()
        }
        didSendAlamofireRequest(request)
        return validationClosure(request).response(queue: resultDeliveryQueue,
                                                   responseSerializer: downloadResponseSerializer(with: request),
                                                   completionHandler: { downloadResponse in
            self.didReceiveDownloadResponse(downloadResponse, forRequest: request)
            completion(downloadResponse)
        })
    }

    internal func downloadResponseSerializer(with request: DownloadRequest) -> DownloadResponseSerializer<Model> {
        return DownloadResponseSerializer<Model> { urlRequest, response, url, error in

            self.willProcessResponse((urlRequest, response, nil, error), for: request)

            var result: Alamofire.Result<Model>
            var apiError: APIError<ErrorModel>?
            var parsedModel: Model?

            if let error = error {
                apiError = self.errorParser(nil, urlRequest, response, url, error)
                // swiftlint:disable:next force_unwrapping
                result = .failure(apiError!)
            } else {
                result = self.responseParser(urlRequest, response, url, error)
                if let model = result.value {
                    parsedModel = model
                    result = .success(model)
                } else {
                    apiError = self.errorParser(result, urlRequest, response, url, error)
                    // swiftlint:disable:next force_unwrapping
                    result = .failure(apiError!)
                }
            }
            if let error = apiError {
                self.didReceiveError(error, for: (urlRequest, response, nil, error), request: request)
            } else if let model = parsedModel {
                self.didSuccessfullyParseResponse((urlRequest, response, nil, error), creating: model, forRequest: request)
            }

            return result
        }
    }
}
