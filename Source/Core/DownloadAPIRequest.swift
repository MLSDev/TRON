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

import Alamofire

public enum DownloadRequestType {
    /// Will create `NSURLSessionDownloadTask` using `downloadTaskWithRequest(_)` method
    case download(DownloadRequest.DownloadFileDestination)
    
    /// Will create `NSURLSessionDownloadTask` using `downloadTaskWithResumeData(_)` method
    case downloadResuming(data: Data, destination: DownloadRequest.DownloadFileDestination)
}

/**
 `DownloadAPIRequest` encapsulates download request creation logic, stubbing options, and response/error parsing.
 */
open class DownloadAPIRequest<ErrorModel>: BaseRequest<EmptyResponse,ErrorModel> {
    
    let type : DownloadRequestType
    
    // Creates `DownloadAPIRequest` with specified `type`, `path` and configures it with to be used with `tron`.
    public init(type: DownloadRequestType, path: String, tron: TRON, errorParser: @escaping ErrorParser) {
        self.type = type
        super.init(path: path, tron: tron,
                   responseParser: { try EmptyResponseParser().parse($0)},
                   errorParser: errorParser)
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
    
    /**
     Perform current request with completion block, that contains Alamofire.Response.
     
     - parameter completion: Alamofire.Response completion block.
     
     - returns: Alamofire.Request or nil if request was stubbed.
     */
    @discardableResult
    open func performCollectingTimeline(withCompletion completion: @escaping ((DownloadResponse<EmptyResponse>) -> Void)) -> DownloadRequest? {
        if performStub(completion: completion) {
            return nil
        }
        return performAlamofireRequest(completion)
    }
    
    private func performAlamofireRequest(_ completion : @escaping (DownloadResponse<EmptyResponse>) -> Void) -> DownloadRequest
    {
        guard let manager = tronDelegate?.manager else {
            fatalError("Manager cannot be nil while performing APIRequest")
        }
        guard let request = alamofireRequest(from: manager) as? DownloadRequest else {
            fatalError("Failed to receive DataRequest")
        }
        if !tronDelegate!.manager.startRequestsImmediately {
            request.resume()
        }
        // Notify plugins about new network request
        let allPlugins = plugins + (tronDelegate?.plugins ?? [])
        allPlugins.forEach {
            $0.willSendRequest(request.request)
        }
        return request.validate().response(queue: resultDeliveryQueue, responseSerializer: responseSerializer(notifyingPlugins: allPlugins), completionHandler: completion)
    }
    
    internal func responseSerializer(notifyingPlugins plugins: [Plugin]) -> DownloadResponseSerializer<EmptyResponse> {
        return DownloadResponseSerializer<EmptyResponse> { urlRequest, response, url, error in
            DispatchQueue.main.async(execute: {
                plugins.forEach {
                    $0.requestDidReceiveResponse((urlRequest, response, nil,error))
                }
            })
            guard error == nil else {
                return .failure(self.errorParser(urlRequest, response, nil,  error))
            }
            return .success(EmptyResponse())
        }
    }
}

