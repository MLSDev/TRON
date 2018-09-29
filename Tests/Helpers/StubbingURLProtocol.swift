//
//  StubbingURLProtocol.swift
//  Tests
//
//  Created by Denys Telezhkin on 9/29/18.
//  Copyright © 2018 Denys Telezhkin. All rights reserved.
//

import Foundation

private func identifier(from request: URLRequest) -> UUID? {
    guard let identifierString = request.value(forHTTPHeaderField: StubbingURLProtocol.Constants.HeaderIdentifier) else { return nil }
    return UUID(uuidString: identifierString)
}

class StubbingURLProtocol : URLProtocol {
    enum Constants {
        static let HeaderIdentifier = "TRON Stub Header Identifier"
    }
    
    static var successResponses = [UUID:Data]()
    static var failureResponses = [UUID:Error]()
    
    override open class func canInit(with request: URLRequest) -> Bool {
        guard let identifier = identifier(from: request) else { return false }
        return successResponses[identifier] != nil || failureResponses[identifier] != nil
    }
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }
    
    override func startLoading() {
        defer {
            client?.urlProtocolDidFinishLoading(self)
        }
        guard let request = task?.currentRequest,
            let identifier = identifier(from: request) else {
            return
        }
        if let successData = StubbingURLProtocol.successResponses[identifier] {
            client?.urlProtocol(self, didLoad: successData)
        } else if let failure = StubbingURLProtocol.failureResponses[identifier] {
            client?.urlProtocol(self, didFailWithError: failure)
        }
    }
    
}
