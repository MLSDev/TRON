//
//  AppDelegate.swift
//  Example
//
//  Created by Denys Telezhkin on 30.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import UIKit
import TRON
import SwiftyJSON

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var tron : TRON!
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let loggerPlugin = NetworkLoggerPlugin()
        loggerPlugin.logSuccess = true
        tron = TRON(baseURL: "https://api.github.com", plugins: [loggerPlugin])
        tron.headerBuilder = HeaderBuilder(defaultHeaders: [:])
        let request : APIRequest<String,Int> = tron.request(path: "zen")
        let token = request.perform(success: { zen in
            print(zen)
            }, failure: { error in
        })
        debugPrint(token)
        // Override point for customization after application launch.
        return true
    }

}

