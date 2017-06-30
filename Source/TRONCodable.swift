//
//  TRONCodable.swift
//  TRON
//
//  Created by Denys Telezhkin on 06.02.16.
//  Copyright © 2015 - present MLSDev. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FRO/Users/denystelezkin/Developer/TRON/.travis.ymlM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import Alamofire

#if swift (>=4.0)

public struct CodableParser<Model: Codable, ErrorModel: Codable> : ErrorHandlingDataResponseSerializerProtocol {
    public typealias SerializedError = ErrorModel
    
    public init() {}
    
    /// A closure used by response handlers that takes a request, response, data and error and returns a result.
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<Model> {
        return { request, response, data, error in
            do {
                let model = try JSONDecoder().decode(Model.self, from: data ?? Data())
                return Result.success(model)
            }
            catch {
                return .failure(error)
            }
        }
    }
}

extension ErrorHandlingDataResponseSerializerProtocol where SerializedError: Codable {
    /// A closure used by response handlers that takes a parsed result, request, response, data and error and returns a serialized error.
    public var serializeError: (Result<SerializedObject>?,URLRequest?, HTTPURLResponse?, Data?, Error?) -> APIError<SerializedError> {
        return { erroredResponse, request, response, data, error in
            let serializationError : Error? = erroredResponse?.error ?? error
            var error = APIError<SerializedError>(request: request, response: response,data: data, error: serializationError)
            error.errorModel = try? JSONDecoder().decode(SerializedError.self, from: data ?? Data())
            return error
        }
    }
}

#endif
