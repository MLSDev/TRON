//
//  TRON+Async.swift
//  TRON
//
//  Created by Denys Telezhkin on 11.06.2021.
//  Copyright © 2021 Denys Telezhkin. All rights reserved.
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

#if compiler(>=5.6.0) && canImport(_Concurrency)

extension DispatchQueue {
    fileprivate static let singleEventQueue = DispatchQueue(label: "org.MLSDev.TRON.concurrencySingleEventQueue",
                                                            attributes: .concurrent)
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
/// Object, responsible for sending APIRequest or UploadAPIRequest when using Swift Concurrency.
public final class RequestSender<Model, ErrorModel: ErrorSerializable> {

    /// Whether request was explicitly cancelled
    public var isCancelled: Bool = false

    /// Asynchronous stream of uploadProgress events.
    public private(set) lazy var uploadProgress: AsyncStream<Progress> = .init(bufferingPolicy: .unbounded) { continuation in
        self.uploadProgressContinuation = continuation
    }

    private var uploadProgressContinuation: AsyncStream<Progress>.Continuation?
    private var cancellableToken: RequestCancellable?
    private var sendRequestWithAlamofireResponse: ((CheckedContinuation<AFDataResponse<Model>, Never>) -> RequestCancellable)?

    internal init(_ request: APIRequest<Model, ErrorModel>) {
        self.sendRequestWithAlamofireResponse = { continuation in
            request.performCollectingTimeline { response in
                continuation.resume(returning: response)
            }.uploadProgress(queue: .singleEventQueue) { [weak self] progress in
                self?.uploadProgressContinuation?.yield(progress)
                if progress.isFinished {
                    self?.uploadProgressContinuation?.finish()
                    self?.uploadProgressContinuation = nil
                }
            }
        }
    }

    internal init(_ request: UploadAPIRequest<Model, ErrorModel>) {
        self.sendRequestWithAlamofireResponse = { continuation in
            request.performCollectingTimeline { response in
                continuation.resume(returning: response)
            }
        }
    }

    /// `Result` of sent request
    public var result: Result<Model, ErrorModel> {
        get async {
            await withTaskCancellationHandler(handler: {
                self.cancel()
            }, operation: {
                if isCancelled {
                    return .failure(ErrorModel(request: nil, response: nil, data: nil, error: URLError(.cancelled)))
                } else {
                    let asyncResponse = await response
                    switch asyncResponse.result {
                    case .success(let model):
                        return .success(model)
                    case .failure(let error):
                        return .failure(error.underlyingError as? ErrorModel ?? ErrorModel(request: asyncResponse.request,
                                                                                           response: asyncResponse.response,
                                                                                           data: asyncResponse.data,
                                                                                           error: asyncResponse.error))
                    }
                }
            })
        }
    }

    /// `Model` returned by request or `ErrorModel` thrown as error.
    public var value: Model {
        get async throws {
            try await result.get()
        }
    }

    /// `DataResponse` produced by the `DataRequest` and its response handler.
    public var response: AFDataResponse<Model> {
        get async {
            await withTaskCancellationHandler(handler: {
                self.cancel()
            }, operation: {
                await withCheckedContinuation { continuation in
                    if let sendRequest = self.sendRequestWithAlamofireResponse {
                        self.cancellableToken = sendRequest(continuation)
                    } else {
                        continuation.resume(with: .success(.init(request: nil,
                                                                 response: nil,
                                                                 data: nil,
                                                                 metrics: nil,
                                                                 serializationDuration: 0,
                                                                 result: .failure(.explicitlyCancelled))))
                    }
                }
            })
        }
    }

    /// Cancel request
    public func cancel() {
        cancellableToken?.cancelRequest()
        isCancelled = true
        sendRequestWithAlamofireResponse = nil
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
/// Object, responsible for sending DownloadAPIRequest when using Swift Concurrency.
public final class DownloadRequestSender<Model, ErrorModel: DownloadErrorSerializable> {

    /// Whether request was explicitly cancelled
    public var isCancelled: Bool = false

    /// Asynchronous stream of downloadProgress events.
    public private(set) lazy var downloadProgress: AsyncStream<Progress> = .init(bufferingPolicy: .unbounded) { continuation in
        self.downloadProgressContinuation = continuation
    }

    private var downloadProgressContinuation: AsyncStream<Progress>.Continuation?

    private var cancellableToken: RequestCancellable?

    private var sendRequestWithAlamofireResponse: ((CheckedContinuation<AFDownloadResponse<Model>, Never>) -> RequestCancellable)?

    internal init(_ request: DownloadAPIRequest<Model, ErrorModel>) {
        sendRequestWithAlamofireResponse = { continuation in
            request.performCollectingTimeline { response in
                continuation.resume(returning: response)
            }.downloadProgress(queue: .singleEventQueue) { [weak self] progress in
                self?.downloadProgressContinuation?.yield(progress)
                if progress.isFinished {
                    self?.downloadProgressContinuation?.finish()
                    self?.downloadProgressContinuation = nil
                }
            }
        }
    }

    /// `Model` returned by request or `ErrorModel` thrown as error.
    public var value: Model {
        get async throws {
            try await result.get()
        }
    }

    /// `Result` of sent request
    public var result: Result<Model, ErrorModel> {
        get async {
            await withTaskCancellationHandler(handler: {
                self.cancel()
            }, operation: {
                if isCancelled {
                    return .failure(ErrorModel(request: nil, response: nil, fileURL: nil, error: URLError(.cancelled)))
                } else {
                    let asyncResponse = await response
                    switch asyncResponse.result {
                    case .success(let model):
                        return .success(model)
                    case .failure(let error):
                        return .failure(error.underlyingError as? ErrorModel ?? ErrorModel(request: asyncResponse.request,
                                                                                           response: asyncResponse.response,
                                                                                           fileURL: asyncResponse.fileURL,
                                                                                           error: asyncResponse.error))
                    }
                }
            })
        }
    }

    /// `DownloadResponse` produced by the `DownloadRequest` and its response handler.
    public var response: AFDownloadResponse<Model> {
        get async {
            await withTaskCancellationHandler(handler: {
                self.cancel()
            }, operation: {
                await withCheckedContinuation { continuation in
                    if let sendRequest = self.sendRequestWithAlamofireResponse {
                        self.cancellableToken = sendRequest(continuation)
                    } else {
                        continuation.resume(with: .success(.init(request: nil, response: nil, fileURL: nil, resumeData: nil, metrics: nil,
                                                                 serializationDuration: 0, result: .failure(.explicitlyCancelled))))
                    }
                }
            })
        }
    }

    /// Returns downloaded file url if successful or throws ErrorModel if not.
    public var responseURL: URL {
        get async throws {
            let response = await response

            if let fileURL = response.fileURL {
                return fileURL
            } else {
                throw DownloadError(response)
            }
        }
    }

    /// Cancel request
    public func cancel() {
        cancellableToken?.cancelRequest()
        isCancelled = true
        sendRequestWithAlamofireResponse = nil
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
/// `APIRequest` extension for Swift Concurrency
public extension APIRequest {

    /// Creates request sender to send request using Swift Concurrency
    func sender() -> RequestSender<Model, ErrorModel> {
        RequestSender(self)
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
/// `UploadAPIRequest` extension for Swift Concurrency
public extension UploadAPIRequest {
    /// Creates request sender to send request using Swift Concurrency
    func sender() -> RequestSender<Model, ErrorModel> {
        RequestSender(self)
    }
}

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
/// `DownloadAPIRequest` extension for Swift Concurrency
public extension DownloadAPIRequest {
    /// Creates request sender to send request using Swift Concurrency
    func sender() -> DownloadRequestSender<Model, ErrorModel> {
        DownloadRequestSender(self)
    }
}

#endif
