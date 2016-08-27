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
    static func parse<T: Parseable>(_ data: Data) throws -> T {
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
    
    static func decode(_ data: Data) -> DecodedType
}

class AssociatedType: ForeignAssociatedTypeParser, Parseable {
    static func decode(_ data: Data) -> AssociatedType {
        return try! parse(data)
    }
    
    static func parse<T : Parseable>(_ data: Data) throws -> T {
        return AssociatedType() as! T
    }
}

protocol ForeignGenericFuncParser {
    static func parse<T>(_ newData: Data) -> T
}

extension ForeignGenericFuncParser where Self: Parseable {
    static func parse<T: Parseable>(_ data: Data) throws -> T {
        guard let foo = T.self as? ForeignGenericFuncParser.Type else {
            throw ParsingError.wrongType
        }
        return foo.parse(data)
    }
}

class Generic: ForeignGenericFuncParser, Parseable {
    static func parse<T>(_ newData: Data) -> T {
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
        let _ : APIRequest<Constructor,TronError> = tron.request("bar")
    }
    
    func testForeignAssociatedTypeParserWorks() {
        let _ : APIRequest<AssociatedType,TronError> = tron.request("bar")
    }
    
    func testForeignGenericFuncParserWorks() {
        let _ : APIRequest<Generic,TronError> = tron.request("bar")
    }
    
}
