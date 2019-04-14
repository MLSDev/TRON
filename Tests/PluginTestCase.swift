//
//  PluginTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 30.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
import Alamofire

class PluginTestCase: ProtocolStubbedTestCase {
    
    func testGlobalPluginsAreCalledCorrectly() {
        let pluginTester = PluginTester()
        let request : APIRequest<Int,APIError> = tron.swiftyJSON.request("status/200")
        request.plugins.append(pluginTester)
        request.stubStatusCode(200)
        
        let waitingForRequest = expectation(description: "wait for request")
        request.performCollectingTimeline(withCompletion: { result in
            waitingForRequest.fulfill()
        })
        
        waitForExpectations(timeout: 1)
        XCTAssertTrue(pluginTester.willSendCalled)
        XCTAssertTrue(pluginTester.willSendAlamofireCalled)
        XCTAssertTrue(pluginTester.didSendAlamofireCalled)
        XCTAssertTrue(pluginTester.didReceiveResponseCalled)
    }
    
    func testLocalPluginsAreCalledCorrectly() {
        let pluginTester = PluginTester()
        let request: APIRequest<String,APIError> = tron.swiftyJSON.request("status/200")
        request.plugins.append(pluginTester)
        request.stubStatusCode(200)
        let expectation = self.expectation(description: "PluginTester expectation")
        request.plugins.append(pluginTester)
        request.perform(withSuccess: { _ in
            if pluginTester.didReceiveResponseCalled && pluginTester.willSendCalled {
                expectation.fulfill()
            }
        }, failure: { error in
            if pluginTester.didReceiveResponseCalled && pluginTester.willSendCalled {
                expectation.fulfill()
            }
        })
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testPluginsAreInitializable() {
        let _ = NetworkLoggerPlugin()
        #if os(iOS)
            let _ = NetworkActivityPlugin(application: UIApplication.shared)
        #endif
        
    }
    
    func testMultipartRequestsCallGlobalAndLocalPlugins() {
        let globalPluginTester = PluginTester()
        let localPluginTester = PluginTester()
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [StubbingURLProtocol.self]
        tron = TRON(baseURL: "https://httpbin.org", session: Session(configuration: configuration))
        let request: UploadAPIRequest<String,APIError> = tron.swiftyJSON.uploadMultipart("status/200") { formData in }
        request.stubStatusCode(200)
        request.plugins.append(localPluginTester)
        tron.plugins.append(globalPluginTester)
        
        let waitForRequest = expectation(description: "waiting for request")
        request.perform(withSuccess: { _ in
            waitForRequest.fulfill()
        }, failure: { error in
            waitForRequest.fulfill()
        })
        waitForExpectations(timeout: 1)
        XCTAssertTrue(localPluginTester.willSendCalled)
        XCTAssertTrue(globalPluginTester.willSendCalled)
        XCTAssertTrue(localPluginTester.didReceiveResponseCalled)
        XCTAssertTrue(globalPluginTester.didReceiveResponseCalled)
    }
    
}
