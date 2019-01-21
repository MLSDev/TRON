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

class StubbingURLProtocol : URLProtocol {
    enum Constants {
        static let HeaderIdentifier = "TRON Stub Header Identifier"
    }
    
    static var successResponses = [UUID:Data]()
    static var failureResponses = [UUID:Error]()
    static var responseCodes = [UUID:Int]()
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let identifier = identifier(from: request) else { return false }
        return successResponses[identifier] != nil || failureResponses[identifier] != nil
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let identifier = identifier(from: request) else {
            return
        }
        if let successData = StubbingURLProtocol.successResponses[identifier] {
            if let code = StubbingURLProtocol.responseCodes[identifier] {
                client?.urlProtocol(self, didReceive: HTTPURLResponse(url: NSURL() as URL,
                                                                      statusCode: code,
                                                                      httpVersion: "HTTP/1.1",
                                                                      headerFields: nil)!,
                                    cacheStoragePolicy: .allowed)
            }
            client?.urlProtocol(self, didLoad: successData)
            client?.urlProtocolDidFinishLoading(self)
        } else if let failure = StubbingURLProtocol.failureResponses[identifier] {
            if let code = StubbingURLProtocol.responseCodes[identifier] {
                client?.urlProtocol(self, didReceive: HTTPURLResponse(url: NSURL() as URL,
                                                                      statusCode: code,
                                                                      httpVersion: "HTTP/1.1",
                                                                      headerFields: nil)!,
                                    cacheStoragePolicy: .allowed)
            }
            client?.urlProtocol(self, didFailWithError: failure)
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {
        guard let identifier = identifier(from: request) else { return }
        StubbingURLProtocol.successResponses[identifier] = nil
        StubbingURLProtocol.failureResponses[identifier] = nil
        StubbingURLProtocol.responseCodes[identifier] = nil
    }
    
}

struct DummyError : Error {}

extension BaseRequest {
    func stubSuccess(_ data: Data, statusCode: Int? = nil) {
        let identifier = UUID()
        headers.add(name: StubbingURLProtocol.Constants.HeaderIdentifier, value: identifier.uuidString)
        StubbingURLProtocol.successResponses[identifier] = data
        if let code = statusCode {
            StubbingURLProtocol.responseCodes[identifier] = code
        }
    }
    
    func stubFailure(_ error: Error = DummyError(), statusCode: Int? = nil) {
        let identifier = UUID()
        headers.add(name: StubbingURLProtocol.Constants.HeaderIdentifier, value: identifier.uuidString)
        StubbingURLProtocol.failureResponses[identifier] = error
        if let code = statusCode {
            StubbingURLProtocol.responseCodes[identifier] = code
        }
    }
}
