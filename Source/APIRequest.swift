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
open class APIRequest<Model, ErrorModel: ErrorSerializable>: BaseRequest<Model, ErrorModel> {

    /// Serializes received response into Result<Model>
    open var responseParser: ResponseParser

    /// Serializes received error into APIError<ErrorModel>
    open var errorParser: ErrorParser

    /// Closure that is applied to request before it is sent.
    open var validationClosure: (DataRequest) -> DataRequest = { $0.validate() }

    /// Creates `APIRequest`, filling `responseParser` and `errorParser` properties
    public init<Serializer: DataResponseSerializerProtocol>(path: String, tron: TRON, responseSerializer: Serializer)
        where Serializer.SerializedObject == Model {
        self.responseParser = { request, response, data, error in
            try responseSerializer.serialize(request: request, response: response, data: data, error: error)
        }
        self.errorParser = { model, request, response, data, error in
            ErrorModel(serializedObject: model, request: request, response: response, data: data, error: error)
        }
        super.init(path: path, tron: tron)
    }

    override func alamofireRequest(from manager: Session) -> Request {
        return manager.request(urlBuilder.url(forPath: path), method: method,
                               parameters: parameters,
                               encoding: parameterEncoding,
                               headers: headers)
    }

    @discardableResult
    /**
     Send current request.
     
     - parameter successBlock: Success block to be executed when request finished
     
     - parameter failureBlock: Failure block to be executed if request fails. Nil by default.
     
     - returns: Alamofire.Request or nil if request was stubbed.
     */
    open func perform(withSuccess successBlock: ((Model) -> Void)? = nil, failure failureBlock: ((ErrorModel) -> Void)? = nil) -> Alamofire.DataRequest {
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
    open func performCollectingTimeline(withCompletion completion: @escaping ((Alamofire.DataResponse<Model>) -> Void)) -> Alamofire.DataRequest {
        return performAlamofireRequest(completion)
    }

    private func performAlamofireRequest(_ completion : @escaping (DataResponse<Model>) -> Void) -> DataRequest {
        guard let session = tronDelegate?.session else {
            fatalError("Manager cannot be nil while performing APIRequest")
        }
        willSendRequest()
        guard let request = alamofireRequest(from: session) as? DataRequest else {
            fatalError("Failed to receive DataRequest")
        }
        if let stub = apiStub, stub.isEnabled {
            request.tron_apiStub = stub
        }
        willSendAlamofireRequest(request)
        if !session.startRequestsImmediately {
            request.resume()
        }
        didSendAlamofireRequest(request)

        return validationClosure(request)
            .performResponseSerialization(queue: resultDeliveryQueue,
                                          responseSerializer: dataResponseSerializer(with: request),
                                          completionHandler: { dataResponse in
            self.didReceiveDataResponse(dataResponse, forRequest: request)
            completion(dataResponse)
        })
    }

    internal func dataResponseSerializer(with request: Request) -> TRONDataResponseSerializer<Model> {
        return TRONDataResponseSerializer { urlRequest, response, data, error in
            self.willProcessResponse((urlRequest, response, data, error), for: request)
            let parsedModel: Model
            let parsedError: ErrorModel?
            do {
                parsedModel = try self.responseParser(urlRequest, response, data, error)
                parsedError = self.errorParser(parsedModel, urlRequest, response, data, error)
            } catch let catchedError {
                parsedError = self.errorParser(nil, urlRequest, response, data, catchedError)
                self.didReceiveError(parsedError, for: (urlRequest, response, data, error), request: request)
                throw parsedError ?? catchedError
            }
            if let nonNilError = parsedError {
                self.didReceiveError(nonNilError, for: (urlRequest, response, data, error), request: request)
                throw nonNilError
            } else {
                self.didSuccessfullyParseResponse((urlRequest, response, data, error), creating: parsedModel, forRequest: request)
                return parsedModel
            }
        }
    }

    internal func didReceiveError(_ error: ErrorModel?, for response: (URLRequest?, HTTPURLResponse?, Data?, Error?), request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.didReceiveError(error, forResponse: response, request: request, formedFrom: self)
        }
    }
}
