//
//  ArgoDecodable.swift
//  TRON
//
//  Created by Denys Telezhkin on 07.02.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
//import Argo

//public struct ArgoDecodableError : ErrorType {}
//
//public protocol ArgoResponseParseable: ResponseParseable {
//    func fromJSON(json: JSON) -> ModelType
//}
//
//public extension Decodable where Self: ArgoResponseParseable {
//    func fromJSON(json: JSON) -> ModelType {
//        return Self.decode(json) as! ModelType
//    }
//}
//
//
//public extension ResponseParseable where Self.ModelType: ArgoResponseParseable {
//    
//    public static func from(json: AnyObject) throws -> ResponseBox<ModelType> {
//        let json = JSON.parse(json)
//        let decoded = ModelType(json: json)
//        guard let decodedValue = decoded.value as? ModelType else {
//            throw ArgoDecodableError()
//        }
//        return ResponseBox(response: decodedValue)
//    }
//}
