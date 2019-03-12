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
