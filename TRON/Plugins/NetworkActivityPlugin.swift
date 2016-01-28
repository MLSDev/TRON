//
//  NetworkActivityPlugin.swift
//  Hint
//
//  Created by Denys Telezhkin on 20.01.16.
//  Copyright © 2016 MLSDev. All rights reserved.
//

import Foundation
import UIKit

class NetworkActivityPlugin : Plugin {
    static var networkActivityCount = 0 {
        didSet {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = networkActivityCount > 0
        }
    }
    
    func willSendRequest(request: NSURLRequest?) {
        self.dynamicType.networkActivityCount++
    }
    
    func requestDidReceiveResponse(response: (NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?)) {
        self.dynamicType.networkActivityCount--
    }
}