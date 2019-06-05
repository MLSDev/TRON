//
//  ProtocolStubbedTestCase.swift
//  Tests
//
//  Created by Denys Telezhkin on 1/23/19.
//  Copyright © 2019 Denys Telezhkin. All rights reserved.
//

class ProtocolStubbedTestCase: XCTestCase {

    var tron: TRON!
    
    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [StubbingURLProtocol.self]
        configuration.urlCache = nil
        configuration.urlCredentialStorage = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        tron = TRON(baseURL: "https://httpbin.org", session: Session(configuration: configuration,
                                                                     startRequestsImmediately: false))
    }
    
    override func tearDown() {
        super.tearDown()
        tron = nil
        StubbingURLProtocol.cleanUp()
    }
}
