//
//  URLBuilderTestCase.swift
//  TRON
//
//  Created by Denys Telezhkin on 28.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import XCTest
import TRON
import Nimble

class URLBuilderTestCase: XCTestCase {
    
    let tron = TRON(baseURL: "https://github.com")
    
    func testURLBuildableAppendsPathComponent() {
        expect(self.tron.urlBuilder.urlForPath("foo").absoluteString) == "https://github.com/foo"
        expect(self.tron.urlBuilder.urlForPath("/bar").absoluteString) == "https://github.com/bar"
    }
    
}
