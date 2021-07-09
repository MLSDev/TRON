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

// swiftlint:disable all

#if swift(>=5.5)

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
final class RequestSender<Model, ErrorModel: ErrorSerializable> {
    
    var cancellableToken: RequestCancellable?
    var sendRequest: ((CheckedContinuation<Model,Error>) -> RequestCancellable)?
    var isCancelled : Bool = false
    
    init(_ request: APIRequest<Model, ErrorModel>) {
        self.sendRequest = { continuation in
            request.perform { model in
                continuation.resume(returning: model)
            } failure: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    init(_ request: UploadAPIRequest<Model,ErrorModel>) {
        self.sendRequest = { continuation in
            request.perform { model in
                continuation.resume(returning: model)
            } failure: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    func send() async throws -> Model {
        try await withTaskCancellationHandler(handler: {
            self.cancel()
        }, operation: {
            if isCancelled {
                throw URLError(.cancelled)
            } else {
                return try await withCheckedThrowingContinuation { continuation in
                    self.cancellableToken = self.sendRequest?(continuation)
                }
            }
        })
    }
    
    func sendHandle() -> Task.Handle<Model, Error> {
        async {
            return try await send()
        }
    }
    
    func cancel() {
        cancellableToken?.cancelRequest()
        isCancelled = true
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
final class DownloadRequestSender<Model, ErrorModel: DownloadErrorSerializable> {
    
    var cancellableToken: RequestCancellable?
    var sendRequest: ((CheckedContinuation<Model,Error>) -> RequestCancellable)?
    var sendRequestAndReturnURL: ((CheckedContinuation<URL,Error>) -> RequestCancellable)?
    var isCancelled : Bool = false
    
    init(_ request: DownloadAPIRequest<Model, ErrorModel>) {
        sendRequest = { continuation in
            request.perform { model in
                continuation.resume(returning: model)
            } failure: { error in
                continuation.resume(throwing: error)
            }
        }
        sendRequestAndReturnURL = { continuation in
            request.performCollectingTimeline { response in
                if let url = response.fileURL {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: response.error ?? DownloadError(response))
                }
            }
        }
    }
    
    func send() async throws -> Model {
        try await withTaskCancellationHandler(handler: {
            self.cancel()
        }, operation: {
            if isCancelled {
                throw URLError(.cancelled)
            } else {
                return try await withCheckedThrowingContinuation { continuation in
                    self.cancellableToken = self.sendRequest?(continuation)
                }
            }
        })
    }
    
    func send() async throws -> URL {
        try await withTaskCancellationHandler(handler: {
            self.cancel()
        }, operation: {
            if isCancelled {
                throw URLError(.cancelled)
            } else {
                return try await withCheckedThrowingContinuation { continuation in
                    self.cancellableToken = self.sendRequestAndReturnURL?(continuation)
                }
            }
        })
    }
    
    func sendHandle() -> Task.Handle<Model, Error> {
        async {
            return try await send()
        }
    }
    
    func sendURLHandle() -> Task.Handle<URL, Error> {
        async {
            return try await send()
        }
    }
    
    func cancel() {
        cancellableToken?.cancelRequest()
        isCancelled = true
        sendRequest = nil
        sendRequestAndReturnURL = nil
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public extension APIRequest {
    func response() async throws -> Model {
        try await RequestSender(self).send()
    }
    
    func responseTaskHandle() -> Task.Handle<Model, Error> {
        RequestSender(self).sendHandle()
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public extension UploadAPIRequest {
    func response() async throws -> Model {
        try await RequestSender(self).send()
    }
    
    func responseTaskHandle() -> Task.Handle<Model, Error> {
        RequestSender(self).sendHandle()
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public extension DownloadAPIRequest {
    func response() async throws -> Model {
        try await DownloadRequestSender(self).send()
    }
    
    func responseTaskHandle() -> Task.Handle<Model, Error> {
        DownloadRequestSender(self).sendHandle()
    }
    
    func responseURL() async throws -> URL {
        try await DownloadRequestSender(self).send()
    }
    
    func responseURLTaskHandle() -> Task.Handle<URL, Error> {
        DownloadRequestSender(self).sendURLHandle()
    }
}
#endif
