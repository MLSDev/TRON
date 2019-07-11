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
import TRONSwiftyJSON

class User: JSONDecodable {
    required init(json: JSON) {
        
    }
}

class UserRequestFactory
{
    static let tron = TRON(baseURL: "https://api.myapp.com")
    
    class func create() -> APIRequest<User,APIError> {
        let request: APIRequest<User,APIError> = tron.swiftyJSON.request("users")
        request.method = .post
        return request
    }
    
    class func read(id: Int) -> APIRequest<User, APIError> {
        return tron.swiftyJSON.request("users/\(id)")
    }
    
    class func update(id: Int, parameters: [String:AnyObject]) -> APIRequest<User, APIError> {
        let request: APIRequest<User,APIError> = tron.swiftyJSON.request("users/\(id)")
        request.method = .put
        request.parameters = parameters
        return request
    }
    
    class func delete(id: Int) -> APIRequest<User,APIError> {
        let request: APIRequest<User,APIError> = tron.swiftyJSON.request("users/\(id)")
        request.method = .delete
        return request
    }
}
