//
//  NetworkLoggerPlugin.swift
//  Hint
//
//  Created by Denys Telezhkin on 20.01.16.
//  Copyright © 2016 MLSDev. All rights reserved.
//

import Foundation

class NetworkLoggerPlugin : Plugin {
    static var logSuccess = false
    static var logFailures = true
    
    func willSendRequest(request: NSURLRequest?) {
        
    }
    
    func requestDidReceiveResponse(response: (NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?)) {
        if response.3 != nil {
            if self.dynamicType.logFailures {
                print("[Request] error\n ->  \(response.0?.URLString ?? "")) \n Response: \(response.1)\n ResponseString: \(String.init(data: response.2 ?? NSData(), encoding: NSUTF8StringEncoding)) \n Error: \(response.3)")
            }
        } else {
            if self.dynamicType.logSuccess {
                print("[Request] success\n ->  \(response.0?.URLString ?? "")")
            }
        }
    }
}