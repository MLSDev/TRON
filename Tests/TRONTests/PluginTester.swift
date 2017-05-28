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
    var didReceiveError = false
    var didReceiveSuccess = false
    
    func willSendRequest<Model, ErrorModel>(_ request: BaseRequest<Model, ErrorModel>) {
        willSendCalled = true
    }
    
    func willSendAlamofireRequest<Model, ErrorModel>(_ request: Request, formedFrom: BaseRequest<Model, ErrorModel>) {
        willSendAlamofireCalled = true
    }
    
    func didSendAlamofireRequest<Model, ErrorModel>(_ request: Request, formedFrom: BaseRequest<Model, ErrorModel>) {
        didSendAlamofireCalled = true
    }
    
    func willProcessResponse<Model, ErrorModel>(response: (URLRequest?, HTTPURLResponse?, Data?, Error?), forRequest request: Request, formedFrom: BaseRequest<Model, ErrorModel>) {
        didReceiveResponseCalled = true
    }
    
    func didSuccessfullyParseResponse<Model, ErrorModel>(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?), creating result: Model, forRequest request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {
        didReceiveSuccess = true
    }
    
    func didReceiveError<Model, ErrorModel>(_ error: APIError<ErrorModel>, forResponse response: (URLRequest?, HTTPURLResponse?, Data?, Error?), request: Request, formedFrom tronRequest: BaseRequest<Model, ErrorModel>) {
        didReceiveError = true
    }
}
