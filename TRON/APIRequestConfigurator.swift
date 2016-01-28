//
//  APIRequestConfigurator.swift
//  Hint
//
//  Created by Denys Telezhkin on 20.01.16.
//  Copyright © 2016 MLSDev. All rights reserved.
//

import Foundation

class APIRequestConfigurator
{
    static var headerBuilder : HeaderBuildable = JSONHeaderBuilder()
    static var urlBuilder : NSURLBuildable = RequestBuilder()
    static var stubbingEnabled : Bool = false
    static var plugins : [Plugin] = []
    
    static func registerPlugin(plugin: Plugin) {
        plugins.append(plugin)
    }
}