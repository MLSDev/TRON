//
//  PluginTester.swift
//  TRON
//
//  Created by Denys Telezhkin on 30.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
import TRON

class PluginTester : Plugin
{
    var willSendCalled = false
    var didReceiveResponseCalled = false
    
    func willSendRequest(_ request: URLRequest?) {
        willSendCalled = true
    }
    
    func requestDidReceiveResponse(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?)) {
        didReceiveResponseCalled = true
    }
}
