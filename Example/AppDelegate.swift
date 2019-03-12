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
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var tron : TRON!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        let loggerPlugin = NetworkLoggerPlugin()
        loggerPlugin.logSuccess = true
        tron = TRON(baseURL: "https://api.github.com", plugins: [loggerPlugin])
        let request : APIRequest<String,APIError> = tron.request("zen", responseSerializer: StringResponseSerializer(encoding: .utf8))
        let token = request.perform(withSuccess: { zen in
                print(zen)
            }, failure: { error in
                print(error)
            })
        debugPrint(token ?? "")
        // Override point for customization after application launch.
        return true
    }

}

