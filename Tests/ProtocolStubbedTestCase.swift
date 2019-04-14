//
//  ProtocolStubbedTestCase.swift
//  Tests
//
//  Created by Denys Telezhkin on 1/23/19.
//  Copyright © 2019 Denys Telezhkin. All rights reserved.
//

import XCTest
@testable import TRON
import Alamofire

class ProtocolStubbedTestCase: XCTestCase {

    var tron: TRON!
    
    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [StubbingURLProtocol.self]
        tron = TRON(baseURL: "https://httpbin.org", session: Session(configuration: configuration))
        URLProtocol.registerClass(StubbingURLProtocol.self)
    }
    
    override func tearDown() {
        super.tearDown()
        tron = nil
        URLProtocol.unregisterClass(StubbingURLProtocol.self)
        StubbingURLProtocol.cleanUp()
    }
    
    override func waitForExpectations(timeout: TimeInterval, handler: XCWaitCompletionHandler? = nil) {
        super.waitForExpectations(timeout: timeout) { error in
            print(error?.localizedDescription ?? "")
        }
    }

}
