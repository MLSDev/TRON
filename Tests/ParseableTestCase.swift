//
//  ParseableTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 10.07.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
import XCTest
import TRON
import Alamofire
import Nimble

protocol ForeignConstructorParser {
    init(data: Data)
}

extension ForeignConstructorParser where Self: Parseable {
    static func parse<T: Parseable>(data: Data) throws -> T {
        guard let foo = T.self as? ForeignConstructorParser.Type else {
            throw ParsingError.wrongType
        }
        return foo.init(data: Data()) as! T
    }
}

class Constructor : ForeignConstructorParser, Parseable {
    required init(data: Data) {
        
    }
}

protocol ForeignAssociatedTypeParser {
    associatedtype DecodedType = Self
    
    static func decode(data: Data) -> DecodedType
}

class AssociatedType: ForeignAssociatedTypeParser, Parseable {
    static func decode(data: Data) -> AssociatedType {
        return try! parse(data: data)
    }
    
    static func parse<T : Parseable>(data: Data) throws -> T {
        return AssociatedType() as! T
    }
}

protocol ForeignGenericFuncParser {
    static func parse<T>(newData: Data) -> T
}

extension ForeignGenericFuncParser where Self: Parseable {
    static func parse<T: Parseable>(data: Data) throws -> T {
        guard let foo = T.self as? ForeignGenericFuncParser.Type else {
            throw ParsingError.wrongType
        }
        return foo.parse(newData: data)
    }
}

class Generic: ForeignGenericFuncParser, Parseable {
    static func parse<T>(newData: Data) -> T {
        return Generic() as! T
    }
}

class ParseableTestCase: XCTestCase {
    
    var tron : TRON!
    
    override func setUp() {
        super.setUp()
        tron = TRON(baseURL: "foo")
    }
    
    func testForeignConstructorParserWorks() {
        let _ : APIRequest<Constructor,TronError> = tron.request(path: "bar")
    }
    
    func testForeignAssociatedTypeParserWorks() {
        let _ : APIRequest<AssociatedType,TronError> = tron.request(path: "bar")
    }
    
    func testForeignGenericFuncParserWorks() {
        let _ : APIRequest<Generic,TronError> = tron.request(path: "bar")
    }
    
}
