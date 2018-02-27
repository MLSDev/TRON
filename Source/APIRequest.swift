//
//  APIRequest.swift
//  TRON
//
//  Created by Anton Golikov on 08.12.15.
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

import Alamofire

/**
 `APIRequest` encapsulates request creation logic, stubbing options, and response/error parsing. 
 */
open class APIRequest<Model, ErrorModel>: BaseRequest<Model, ErrorModel> {

    /// Serializes received response into Result<Model>
    open var responseParser: ResponseParser

    /// Serializes received error into APIError<ErrorModel>
    open var errorParser: ErrorParser

    /// Closure that is applied to request before it is sent.
    open var validationClosure: (DataRequest) -> DataRequest = { $0.validate() }

    /// Creates `APIRequest`, filling `responseParser` and `errorParser` properties
    public init<Serializer: ErrorHandlingDataResponseSerializerProtocol>(path: String, tron: TRON, responseSerializer: Serializer)
        where Serializer.SerializedObject == Model, Serializer.SerializedError == ErrorModel {
        self.responseParser = { request, response, data, error in
            responseSerializer.serializeResponse(request, response, data, error)
        }
        self.errorParser = { result, request, response, data, error in
            return responseSerializer.serializeError(result, request, response, data, error)
        }
        super.init(path: path, tron: tron)
    }

    override func alamofireRequest(from manager: SessionManager) -> Request {
            return manager.request(urlBuilder.url(forPath: path), method: method,
                                   parameters: parameters,
                                   encoding: parameterEncoding,
                                   headers: headerBuilder.headers(forAuthorizationRequirement: authorizationRequirement, including: headers))
    }

    @discardableResult
    /**
     Send current request.
     
     - parameter successBlock: Success block to be executed when request finished
     
     - parameter failureBlock: Failure block to be executed if request fails. Nil by default.
     
     - returns: Alamofire.Request or nil if request was stubbed.
     */
    open func perform(withSuccess successBlock: ((Model) -> Void)? = nil, failure failureBlock: ((APIError<ErrorModel>) -> Void)? = nil) -> Alamofire.DataRequest? {
        if performStub(success: successBlock, failure: failureBlock) {
            return nil
        }
        return performAlamofireRequest {
            self.callSuccessFailureBlocks(successBlock, failure: failureBlock, response: $0)
        }
    }

    @discardableResult
    /**
     Perform current request with completion block, that contains Alamofire.Response.
     
     - parameter completion: Alamofire.Response completion block.
     
     - returns: Alamofire.Request or nil if request was stubbed.
     */
    open func performCollectingTimeline(withCompletion completion: @escaping ((Alamofire.DataResponse<Model>) -> Void)) -> Alamofire.DataRequest? {
        if performStub(completion: completion) {
            return nil
        }
        return performAlamofireRequest(completion)
    }

    private func performAlamofireRequest(_ completion : @escaping (DataResponse<Model>) -> Void) -> DataRequest {
        guard let manager = tronDelegate?.manager else {
            fatalError("Manager cannot be nil while performing APIRequest")
        }
        willSendRequest()
        guard let request = alamofireRequest(from: manager) as? DataRequest else {
            fatalError("Failed to receive DataRequest")
        }
        willSendAlamofireRequest(request)
        if !manager.startRequestsImmediately {
            request.resume()
        }
        didSendAlamofireRequest(request)

        return validationClosure(request).response(queue: resultDeliveryQueue, responseSerializer: dataResponseSerializer(with: request), completionHandler: { dataResponse in
            self.didReceiveDataResponse(dataResponse, forRequest: request)
            completion(dataResponse)
        })
    }

    internal func dataResponseSerializer(with request: Request) -> Alamofire.DataResponseSerializer<Model> {
        return DataResponseSerializer<Model> { urlRequest, response, data, error in

            self.willProcessResponse((urlRequest, response, data, error), for: request)
            var result: Alamofire.Result<Model>
            var apiError: APIError<ErrorModel>?
            var parsedModel: Model?

            if let error = error {
                apiError = self.errorParser(nil, urlRequest, response, data, error)
                // swiftlint:disable:next force_unwrapping
                result = .failure(apiError!)
            } else {
                result = self.responseParser(urlRequest, response, data, error)
                if let model = result.value {
                    parsedModel = model
                    result = .success(model)
                } else {
                    apiError = self.errorParser(result, urlRequest, response, data, error)
                    // swiftlint:disable:next force_unwrapping
                    result = .failure(apiError!)
                }
            }
            if let error = apiError {
                self.didReceiveError(error, for: (urlRequest, response, data, error), request: request)
            } else if let model = parsedModel {
                self.didSuccessfullyParseResponse((urlRequest, response, data, error), creating: model, forRequest: request)
            }

            return result
        }
    }
}
