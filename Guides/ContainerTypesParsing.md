## Parsing container types

Sometimes you may want to parse objects, that are wrapped in various containers, for example Array, Dictionary or Optional. While `TRON` does not provide an out of the box implementation to do that, it's actually pretty easy to do without building a custom response serializer. 

For example, let's say we want to request an Optional User model:

```swift
let request: APIRequest<User?, APIError> = tron.swiftyJSON.request("maybe_user")
```

To make this syntax actually work, we can conform Optional to JSONDecodable in the following way:

```swift
extension Optional : JSONDecodable where Wrapped: JSONDecodable {
    public init(json: JSON) {
        do {
            self = try Wrapped(json: json)
        } catch {
            self = nil
        }
    }
}
```

Similarly, this can be applied to other containers, but we need to consider how throwed errors will be handled. For example, let's say we receive JSON with array of objects, and pass it to response serializer. Then half of object serializers fail because of malformed JSON - or not complete data, and half succeed. Should the entire request be failed, or should we just skip objects, that could not be parsed? 

Because conditional conformance requires a single answer to this question, let's assume that all objects should be well formed and contain required data, or entire request should fail, extension can be written in following way:

```swift
extension Array : JSONDecodable where Element: JSONDecodable {
    public init(json: JSON) throws {
        self = try json.arrayValue.map { try Element(json: $0) }
    }
}
```

And here's how it can be used:

```swift
let request: APIRequest<[User], APIError> = tron.swiftyJSON.request("users")
```

If you need multiple behaviours, then it's a good idea to implement custom response serializer.
