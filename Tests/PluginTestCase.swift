//
//  PluginTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 30.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
import Nimble

class PluginTestCase: XCTestCase {
    
    func testGlobalPluginsAreCalledCorrectly() {
        let pluginTester = PluginTester()
        let tron = TRON(baseURL: "http://httpbin.org", plugins: [pluginTester])
        let request : APIRequest<Int,Int> = tron.request("status/200")
        
        request.performCollectingTimeline(withCompletion: {_ in })
        
        expect(pluginTester.willSendCalled).toEventually(equal(true))
        expect(pluginTester.willSendAlamofireCalled).toEventually(equal(true))
        expect(pluginTester.didSendAlamofireCalled).toEventually(equal(true))
        expect(pluginTester.didReceiveResponseCalled).toEventually(equal(true))
    }
    
    func testLocalPluginsAreCalledCorrectly() {
        let pluginTester = PluginTester()
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: APIRequest<String,Int> = tron.request("status/200")
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
        
        waitForExpectations(timeout: 10, handler: nil)
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
        
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: UploadAPIRequest<String,Int> = tron.uploadMultipart("status/200") { formData in
            
        }
        request.plugins.append(localPluginTester)
        tron.plugins.append(globalPluginTester)
        
        request.performMultipart(withSuccess: { _ = $0 })
        
        expect(localPluginTester.willSendCalled).toEventually(equal(true))
        expect(globalPluginTester.willSendCalled).toEventually(equal(true))
        expect(localPluginTester.didReceiveResponseCalled).toEventually(equal(true))
        expect(globalPluginTester.didReceiveResponseCalled).toEventually(equal(true))
    }
    
}
