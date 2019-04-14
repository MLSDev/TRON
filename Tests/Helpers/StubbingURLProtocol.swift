//
//  StubbingURLProtocol.swift
//  Tests
//
//  Created by Denys Telezhkin on 9/29/18.
//  Copyright © 2018 Denys Telezhkin. All rights reserved.
//

import Foundation
@testable import TRON

private func identifier(from request: URLRequest?) -> UUID? {
    guard let identifierString = request?.value(forHTTPHeaderField: StubbingURLProtocol.Constants.HeaderIdentifier) else { return nil }
    return UUID(uuidString: identifierString)
}

class URLProtocolClientCommunicator {
    enum Message {
        case complete
        case error(Error)
        case response(HTTPURLResponse)
        case data(Data)
    }
    
    let messages : [Message]
    
    init(_ messages: [Message]) {
        self.messages = messages
    }
    
    func communicate(using protokol: URLProtocol, client: URLProtocolClient?) {
        for message in messages {
            switch message {
            case .complete: client?.urlProtocolDidFinishLoading(protokol)
            case .error(let error): client?.urlProtocol(protokol, didFailWithError: error)
            case .response(let response): client?.urlProtocol(protokol,
                                                             didReceive: response,
                                                             cacheStoragePolicy: .allowed)
            case .data(let data): client?.urlProtocol(protokol, didLoad: data)
            }
        }
    }
}

class StubbingURLProtocol : URLProtocol {
    enum Constants {
        static let HeaderIdentifier = "TRON Stub Header Identifier"
    }
    
    static var communicators = [UUID:URLProtocolClientCommunicator]()
    
    static func cleanUp() {
        communicators = [:]
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let identifier = identifier(from: request) else { return false }
        return communicators[identifier] != nil
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let identifier = identifier(from: request) else {
            return
        }
        if let communicator = StubbingURLProtocol.communicators[identifier] {
            communicator.communicate(using: self, client: client)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {
        guard let identifier = identifier(from: request) else { return }
        StubbingURLProtocol.communicators[identifier] = nil
    }
    
}

struct DummyError : Error {}

private extension HTTPURLResponse {
    static func withStatus(_ statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(url: NSURL() as URL, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
    }
}

extension BaseRequest {
    func stubSuccess(_ data: Data, statusCode: Int? = nil) {
        let identifier = UUID()
        headers.add(name: StubbingURLProtocol.Constants.HeaderIdentifier, value: identifier.uuidString)
        var messages = [URLProtocolClientCommunicator.Message]()
        if let statusCode = statusCode {
            messages.append(.response(HTTPURLResponse.withStatus(statusCode)))
        }
        messages.append(.data(data))
        messages.append(.complete)
        StubbingURLProtocol.communicators[identifier] = URLProtocolClientCommunicator(messages)
    }
    
    func stubStatusCode(_ statusCode: Int) {
        let identifier = UUID()
        headers.add(name: StubbingURLProtocol.Constants.HeaderIdentifier, value: identifier.uuidString)
        var messages = [URLProtocolClientCommunicator.Message]()
        messages.append(.response(HTTPURLResponse.withStatus(statusCode)))
        messages.append(.complete)
        StubbingURLProtocol.communicators[identifier] = URLProtocolClientCommunicator(messages)
    }
    
    func stubFailure(_ error: Error = DummyError()) {
        let identifier = UUID()
        headers.add(name: StubbingURLProtocol.Constants.HeaderIdentifier, value: identifier.uuidString)
        var messages = [URLProtocolClientCommunicator.Message]()
        messages.append(.error(error))
        messages.append(.complete)
        StubbingURLProtocol.communicators[identifier] = URLProtocolClientCommunicator(messages)
    }
}
