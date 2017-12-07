## Array response serializer

Ideally, if an element of Array is JSONDecodable or Codable, we want to be able to write this:

```swift
extension Array : JSONDecodable where Element: JSONDecodable
```

However, currently(in Swift 3 and 4), that's not possible, so we are forced to write specific ArrayResponseSerializer. There might be other cases with some API's, for example Array of objects may be wrapped in rootKeyPath, or wrapped into root array. Here's conceptual `ArrayResponseSerializer` class, that handles those cases for `JSONDecodable` protocol:

```swift
import Foundation
import SwiftyJSON
import Alamofire

struct ArrayResponseSerializer<Model: JSONDecodable, ErrorModel: JSONDecodable> : ErrorHandlingDataResponseSerializerProtocol
{
    let keyPath: String?
    let unwrapFromRootArray : Bool

    init(keyPath: String? = nil, unwrapFromRootArray: Bool = false) {
        self.keyPath = keyPath
        self.unwrapFromRootArray = unwrapFromRootArray
    }

    var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<[Model]> {
        return { request, response, data, error in
            let json = (try? JSON(data: data ?? Data())) ?? JSON()

            var unwrapped : JSON
            if self.unwrapFromRootArray {
                unwrapped = json.arrayValue.first ?? JSON([])
            } else {
                unwrapped = json
            }
            if let keyPath = self.keyPath {
                unwrapped = unwrapped.dictionaryValue[keyPath] ?? JSON([])
            }
            return Result.success(unwrapped.arrayValue.flatMap { try? Model(json: $0) })
        }
    }

    var serializeError: (Result<SerializedObject>?,URLRequest?, HTTPURLResponse?, Data?, Error?) -> APIError<ErrorModel> {
        return { erroredResponse, request, response, data, error in
            let serializationError : Error? = erroredResponse?.error ?? error
            var error = APIError<SerializedError>(request: request, response: response,data: data, error: serializationError)
            let data = data ?? Data()
            let json = (try? JSON(data: data)) ?? JSON.null
            error.errorModel = try? SerializedError.init(json: json)
            return error
        }
    }
}
```

## Custom response serializer

Sometimes you want to make completely custom parser, that does not rely on generic constraints. Here's a way to do it:

```swift
import Foundation
import SwiftyJSON
import Alamofire

struct CustomResponseSerializer<T, ErrorModel: JSONDecodable> : ErrorHandlingDataResponseSerializerProtocol
{
    let parser : (Data) throws -> T

    init(dataParser: @escaping (Data) throws -> T ) {
        self.parser = dataParser
    }

    var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<T> {
        return { request, response, data, error in
            do {
                guard let data = data else { throw error ?? NSError() }
                let result = try self.parser(data)
                return Result.success(result)
            } catch {
                return Result.failure(error)
            }
        }
    }

    var serializeError: (Result<SerializedObject>?,URLRequest?, HTTPURLResponse?, Data?, Error?) -> APIError<ErrorModel> {
        return { erroredResponse, request, response, data, error in
            let serializationError : Error? = erroredResponse?.error ?? error
            var error = APIError<SerializedError>(request: request, response: response,data: data, error: serializationError)
            let data = data ?? Data()
            let json = (try? JSON(data: data)) ?? JSON.null
            error.errorModel = try? SerializedError.init(json: json)
            return error
        }
    }
}
```
