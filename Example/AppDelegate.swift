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
    var downloadTRON: TRON!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
//        let loggerPlugin = NetworkLoggerPlugin()
//        loggerPlugin.logSuccess = true
//        tron = TRON(baseURL: "https://api.github.com", plugins: [loggerPlugin])
//        let request : APIRequest<String,APIError> = tron.request("zen", responseSerializer: StringResponseSerializer(encoding: .utf8))
//        let token = request.perform(withSuccess: { zen in
//                print(zen)
//            }, failure: { error in
//                print(error)
//            })
//        debugPrint(token)
        // Override point for customization after application launch.
        
        
        downloadTRON = TRON(baseURL: "", buildingURL: .relativeToBaseURL)
        let downloadRequest: DownloadAPIRequest<URL, APIError> = downloadTRON.download("https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Spodnji_Log_Wooden_Bridge_across_Sava_river_%28Litija_municipality%29.jpg/2880px-Spodnji_Log_Wooden_Bridge_across_Sava_river_%28Litija_municipality%29.jpg", to: DownloadRequest.suggestedDownloadDestination(), responseSerializer: FileURLPassthroughResponseSerializer())
        
        let sender = downloadRequest.sender()
        
        Task {
            for await progress in sender.downloadProgress {
                print(progress)
            }
        }
        Task {
            do {
                let result = try await sender.responseURL
                print(result)
            } catch {
                print("download error: \(error)")
            }
        }
        return true
    }

}

