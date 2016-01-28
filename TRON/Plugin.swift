//
//  Plugin.swift
//  Hint
//
//  Created by Denys Telezhkin on 20.01.16.
//  Copyright © 2016 MLSDev. All rights reserved.
//

import Foundation

protocol Plugin {
    func willSendRequest(request: NSURLRequest?)
    
    func requestDidReceiveResponse(response: (NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?))
}