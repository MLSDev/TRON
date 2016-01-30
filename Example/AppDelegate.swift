//
//  AppDelegate.swift
//  Example
//
//  Created by Denys Telezhkin on 30.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import UIKit
import TRON

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var tron : TRON!
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let loggerPlugin = NetworkLoggerPlugin()
        loggerPlugin.logSuccess = true
        let tron = TRON(baseURL: "http://httpbin.org", plugins: [loggerPlugin])
        let request : APIRequest<Int,Int> = tron.request(path: "headers")
        request.performWithSuccess({ _ in
        })
        // Override point for customization after application launch.
        return true
    }

}

