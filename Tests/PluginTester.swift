//
//  PluginTester.swift
//  TRON
//
//  Created by Denys Telezhkin on 30.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
import TRON
import Alamofire

class PluginTester : Plugin
{
    var willSendCalled = false
    var willSendAlamofireCalled = false
    var didSendAlamofireCalled = false
    var didReceiveResponseCalled = false
    
    func willSendRequest<Model, ErrorModel>(_ request: BaseRequest<Model, ErrorModel>) {
        willSendCalled = true
    }
    
    func willSendAlamofireRequest<Model, ErrorModel>(_ request: Request, formedFrom: BaseRequest<Model, ErrorModel>) {
        willSendAlamofireCalled = true
    }
    
    func didSendAlamofireRequest<Model, ErrorModel>(_ request: Request, formedFrom: BaseRequest<Model, ErrorModel>) {
        didSendAlamofireCalled = true
    }
    
    func didReceiveResponse<Model, ErrorModel>(response: (URLRequest?, HTTPURLResponse?, Data?, Error?), forRequest request: Request, formedFrom: BaseRequest<Model, ErrorModel>) {
        didReceiveResponseCalled = true
    }
}
