//
//  APIStub.swift
//  Hint
//
//  Created by Denys Telezhkin on 11.12.15.
//  Copyright © 2015 MLSDev. All rights reserved.
//

import Foundation
import SwiftyJSON

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

extension APIStub {
    func buildModelFromFile(fileName: String) {
        let bundle = NSBundle(forClass: self.dynamicType)
        if let filePath = bundle.pathForResource(fileName as String, ofType: nil)
        {
            guard let data = NSData(contentsOfFile: filePath),
                let json = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) else {
                    print("failed building response model from file: \(filePath)")
                return
            }
            model = Model(json: JSON(json))
        }
    }
}

class APIStub<Model: JSONDecodable, ErrorModel: JSONDecodable> : Cancellable {
    var successful = true
    var model : Model?
    var error: APIError<ErrorModel>?
    var stubDelay = 0.1
    
    func cancel() {
        
    }
    
    func performStubWithSuccess(success: Model -> Void, failure: (APIError<ErrorModel> -> Void)? = nil) -> Cancellable {
        if let model = model where successful {
            delay(stubDelay) {
                success(model)
            }
        } else if let error = error {
            delay(stubDelay) {
                failure?(error)
            }
        }
        return self
    }
}