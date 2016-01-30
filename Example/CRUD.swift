//
//  CRUD.swift
//  TRON
//
//  Created by Denys Telezhkin on 30.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
import SwiftyJSON
import TRON

class User: JSONDecodable {
    required init(json: JSON) {
        
    }
}

class MyAppError: JSONDecodable {
    required init(json: JSON) {
        
    }
}

class UserRequestFactory
{
    static let tron = TRON(baseURL: "https://api.myapp.com")
    
    class func create() -> APIRequest<User,MyAppError> {
        let request: APIRequest<User,MyAppError> = tron.request(path: "users")
        request.method = .POST
        return request
    }
    
    class func read(id: Int) -> APIRequest<User, MyAppError> {
        return tron.request(path: "users/\(id)")
    }
    
    class func update(id: Int, parameters: [String:AnyObject]) -> APIRequest<User, MyAppError> {
        let request: APIRequest<User,MyAppError> = tron.request(path: "users/\(id)")
        request.method = .PUT
        request.parameters = parameters
        return request
    }
    
    class func delete(id: Int) -> APIRequest<User,MyAppError> {
        let request: APIRequest<User,MyAppError> = tron.request(path: "users/\(id)")
        request.method = .DELETE
        return request
    }
}