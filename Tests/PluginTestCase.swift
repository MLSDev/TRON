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
        let request : APIRequest<Int,Int> = tron.request(path: "status/200")
        
        request.perform(success: {_ in })
        
        expect(pluginTester.didReceiveResponseCalled).toEventually(equal(true))
        expect(pluginTester.willSendCalled).toEventually(equal(true))
    }
    
    func testLocalPluginsAreCalledCorrectly() {
        let pluginTester = PluginTester()
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: APIRequest<String,Int> = tron.request(path: "status/200")
        let expectation = self.expectation(withDescription: "PluginTester expectation")
        request.plugins.append(pluginTester)
        request.perform(success: { _ in
            if pluginTester.didReceiveResponseCalled && pluginTester.willSendCalled {
                expectation.fulfill()
            }
        }, failure: { error in
            if pluginTester.didReceiveResponseCalled && pluginTester.willSendCalled {
                expectation.fulfill()
            }
        })
        
        waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testPluginsAreInitializable() {
        let _ = NetworkLoggerPlugin()
        #if os(iOS)
            let _ = NetworkActivityPlugin(application: UIApplication.sharedApplication())
        #endif
        
    }
    
    func testMultipartRequestsCallGlobalAndLocalPlugins() {
        let globalPluginTester = PluginTester()
        let localPluginTester = PluginTester()
        
        let tron = TRON(baseURL: "http://httpbin.org")
        let request: MultipartAPIRequest<String,Int> = tron.uploadMultipart(path: "status/200") { formData in
            
        }
        request.plugins.append(localPluginTester)
        tron.plugins.append(globalPluginTester)
        
        request.performMultipart(success: { $0 })
        
        expect(localPluginTester.willSendCalled).toEventually(equal(true))
        expect(globalPluginTester.willSendCalled).toEventually(equal(true))
        expect(localPluginTester.didReceiveResponseCalled).toEventually(equal(true))
        expect(globalPluginTester.didReceiveResponseCalled).toEventually(equal(true))
    }
    
}
