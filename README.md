

<p align="center">
  <img src="https://github.com/MLSDev/TRON/blob/master/TRON.png" />
</p>

![Build Status](https://travis-ci.org/MLSDev/TRON.svg?branch=master) &nbsp;
[![codecov.io](http://codecov.io/github/MLSDev/TRON/coverage.svg?branch=master)](http://codecov.io/github/MLSDev/TRON?branch=master)
![CocoaPod platform](https://cocoapod-badges.herokuapp.com/p/TRON/badge.png) &nbsp;
![CocoaPod version](https://cocoapod-badges.herokuapp.com/v/TRON/badge.png) &nbsp;
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Packagist](https://img.shields.io/packagist/l/doctrine/orm.svg)]()

TRON is a lightweight network abstraction layer, built on top of [Alamofire](https://github.com/Alamofire/Alamofire). It can be used to dramatically simplify interacting with RESTful JSON web-services.

## Features

- [x] Generic, protocol-based implementation
- [x] Built-in response and error parsing
- [x] Support for any custom mapper. Defaults to [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) and Codable protocol in Swift 4.
- [x] Support for upload tasks
- [x] Support for download tasks and resuming downloads
- [x] Robust plugin system
- [x] Stubbing of network requests
- [x] Modular architecture
- [x] Support for iOS/Mac OS X/tvOS/watchOS/Linux
- [x] Support for CocoaPods/Carthage/Swift Package Manager
- [x] RxSwift extension

## Overview

We designed TRON to be simple to use and also very easy to customize. After initial setup, using TRON is very straightforward:

```swift
let request: APIRequest<User,MyAppError> = tron.codable.request("me")
request.perform(withSuccess: { user in
  print("Received User: \(user)")
}, failure: { error in
  print("User request failed, parsed error: \(error)")
})
```

## Requirements

- Xcode 8.3/9.x
- Swift 3/4
- iOS 8 / macOS 10.10 / tvOS 9.0 / watchOS 2.0

## Installation

### CocoaPods

```ruby
pod 'TRON', '~> 4.0'
```

Only Core subspec, without SwiftyJSON dependency:

```ruby
pod 'TRON/Core', '~> 4.0'
```

RxSwift extension for TRON:

```ruby
pod 'TRON/RxSwift', '~> 4.0'
```

### Carthage

```ruby
github "MLSDev/TRON", ~> 4.0
```

## Migration Guides

- [TRON 4.0 Migration Guide](https://github.com/MLSDev/TRON/blob/master/Docs/4.0%20Migration%20Guide.md)
- [TRON 2.0 Migration Guide](https://github.com/MLSDev/TRON/blob/master/Docs/2.0%20Migration%20Guide.md)
- [TRON 1.0 Migration Guide](https://github.com/MLSDev/TRON/blob/master/Docs/1.0%20Migration%20Guide.md)

## Project status

`TRON` is under active development by MLSDev Inc. Pull requests are welcome!

## Request building

`TRON` object serves as initial configurator for `APIRequest`, setting all base values and configuring to use with baseURL.

```swift
let tron = TRON(baseURL: "https://api.myapp.com/")
```

You need to keep strong reference to `TRON` object, because it holds Alamofire.Manager, that is running all requests.

### URLBuildable

`URLBuildable` protocol is used to convert relative path to URL, that will be used by request.

```swift
public protocol URLBuildable {
    func url(forPath path: String) -> URL
}
```

By default, `TRON` uses `URLBuilder` class, that simply appends relative path to base URL, which is sufficient in most cases. You can customize url building process globally by changing `urlBuilder` property on `TRON` or locally, for a single request by modifying `urlBuilder` property on `APIRequest`.

### HeaderBuildable

`HeaderBuildable` protocol is used to configure HTTP headers on your request.

```swift
public protocol HeaderBuildable {
    func headers(forAuthorizationRequirement requirement: AuthorizationRequirement, including headers: [String:String]) -> [String: String]
}
```

`AuthorizationRequirement` is an enum with three values:

```swift
public enum AuthorizationRequirement {
    case none, allowed, required
}
```

It represents scenarios where user is not authorized, user is authorized, but authorization is not required, and a case, where request requires authorization.

By default, `TRON` uses `HeaderBuilder` class, which adds "Accept":"application/json" header to your requests.

## Sending requests

To send `APIRequest`, call `perform(withSuccess:failure:)` method on `APIRequest`:

```swift
let alamofireRequest = request.perform(withSuccess: { result in }, failure: { error in})
```

Notice that `alamofireRequest` variable returned from this method is an Alamofire.Request?, that will be nil if request is stubbed.

Alternatively, you can use `performCollectingTimeline(withCompletion:)` method that contains `Alamofire.Response` inside completion closure:

```swift
request.performCollectingTimeline(withCompletion: { response in
    print(response.timeline)
    print(response.result)
})
```

In both cases, you can additionally chain `Alamofire.Request` methods, if you need:

```swift
request.perform(withSuccess: { result in }, failure: { error in })?.progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
    print(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
}
```

## Response parsing

Generic `APIRequest` implementation allows us to define expected response type before request is even sent. We use `Alamofire` `DataResponseSerializerProtocol`, and are adding to it `ErrorHandlingDataResponseSerializerProtocol`, which basically allows us to have two generics for both success and error values.

```swift

// Alamofire 4:

public protocol DataResponseSerializerProtocol {
    associatedtype SerializedObject

    var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<SerializedObject> { get }
}

// TRON:

public protocol ErrorHandlingDataResponseSerializerProtocol : DataResponseSerializerProtocol {
    associatedtype SerializedError

    var serializeError: (Alamofire.Result<SerializedObject>?,URLRequest?, HTTPURLResponse?, Data?, Error?) -> APIError<SerializedError> { get }
}

```

### Codable

Parsing models using Swift4 `Codable` protocol is simple, implement `Codable` protocol:

```swift
struct User: Codable {
  let name : String
  let id: Int
}
```

And send a request:

```swift
let request: APIRequest<User,MyAppError> = tron.codable.request("me")
request.perform(withSuccess: { user in
  print("Received user: \(user.name) with id: \(user.id)")
})
```

It's possible to customize decoders for both model and error parsing:

```swift
let userDecoder = JSONDecoder()
// Customization for user decoder...
let errorDecoder = JSONDecoder()
// Customization for error decoder...

let request : APIRequest<User,MyAppError> = tron.codable(modelDecoder: userDecoder, errorDecoder: errorDecoder).request("me")
```

### JSONDecodable

`TRON` provides `JSONDecodable` protocol, that allows us to parse models using [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON):

```swift
public protocol JSONDecodable {
    init(json: JSON) throws
}
```

To parse your response from the server using `SwiftyJSON`, all you need to do is to create `JSONDecodable` conforming type, for example:

```swift
class User: JSONDecodable {
  let name : String
  let id: Int

  required init(json: JSON) {
    name = json["name"].stringValue
    id = json["id"].intValue
  }
}
```

And send a request:

```swift
let request: APIRequest<User,MyAppError> = tron.swiftyJSON.request("me")
request.perform(withSuccess: { user in
  print("Received user: \(user.name) with id: \(user.id)")
})
```

There are also default implementations of `JSONDecodable` protocol for Swift built-in types like String, Int, Float, Double and Bool, so you can easily do something like this:

```swift
let request : APIRequest<String,MyAppError> = tron.swiftyJSON.request("status")
request.perform(withSuccess: { status in
    print("Server status: \(status)") //
})
```

You can also use `EmptyResponse` struct in cases where you don't care about actual response.

Some concepts for response serialization, including array response serializer, are described in [Response Serializers document](https://github.com/MLSDev/TRON/blob/master/Docs/Response%20Serializers.md)

It's possible to customize `JSONSerialization.ReadingOptions`, that are used by `SwiftyJSON.JSON` object while parsing data of the response:

```swift
let request : APIRequest<String, MyAppError> = tron.swiftyJSON(readingOptions: .allowFragments).request("status")
```

## RxSwift

```swift
let request : APIRequest<Foo, MyError> = tron.codable.request("foo")
_ = request.rxResult().subscribe(onNext: { result in
    print(result)
})
```

```swift
let multipartRequest : UploadAPIREquest<Foo,MyError> = tron.codable.upload("foo", formData: { _ in })
multipartRequest.rxMultipartResult().subscribe(onNext: { result in
    print(result)
})
```

### Error handling

`TRON` includes built-in parsing for errors. `APIError` is a generic class, that includes several default properties, that can be fetched from unsuccessful request:

```swift
struct APIError<T> : Error {
    public let request : URLRequest?
    public let response : HTTPURLResponse?
    public let data : Data?
    public let error : Error?
    public var errorModel: T?
}
```

When `APIRequest` fails, you receive concrete APIError instance, for example, let's define `MyAppError` we have been talking about:

```swift
class MyAppError : JSONDecodable {
  var errors: [String:[String]] = [:]

  required init(json: JSON) {
    if let dictionary = json["errors"].dictionary {
      for (key,value) in dictionary {
          errors[key] = value.arrayValue.map( { return $0.stringValue } )
      }
    }
  }
}
```

This way, you only need to define how your errors are parsed, and not worry about other failure details like response code, because they are already included:

```swift
request.perform(withSuccess: { response in }, failure: { error in
    print(error.request) // Original URLRequest
    print(error.response) // HTTPURLResponse
    print(error.data) // Data of response
    print(error.error) // Error from Foundation Loading system
    print(error.errorModel.errors) // MyAppError parsed property
  })
```

## Using Alamofire custom response serializers

Any custom response serializer for `Alamofire` can be used with TRON, you just need to specify error type, that will be used, for example, if `CustomError` is `JSONDecodable`:

```swift
extension Alamofire.DataResponseSerializer : ErrorHandlingDataResponseSerializerProtocol {
    public typealias SerializedError = CustomError

    public var serializeError: (Result<SerializedObject>?, URLRequest?, HTTPURLResponse?, Data?, Error?) -> APIError<SerializedError> {
        return { erroredResponse, request, response, data, error in
            let serializationError : Error? = erroredResponse?.error ?? error
            var error = APIError<ErrorModel>(request: request, response: response,data: data, error: serializationError)

            // Here you can define, how error needs to be parsed
            error.errorModel =  try? ErrorModel.init(json: JSON(data: data ?? Data()))
            return error
        }
    }
}
```

## CRUD

```swift
struct Users
{
    static let tron = TRON(baseURL: "https://api.myapp.com")

    static func create() -> APIRequest<User,MyAppError> {
        let request: APIRequest<User,MyAppError> = tron.codable.request("users")
        request.method = .post
        return request
    }

    static func read(id: Int) -> APIRequest<User, MyAppError> {
        return tron.codable.request("users/\(id)")
    }

    static func update(id: Int, parameters: [String:Any]) -> APIRequest<User, MyAppError> {
        let request: APIRequest<User,MyAppError> = tron.codable.request("users/\(id)")
        request.method = .put
        request.parameters = parameters
        return request
    }

    static func delete(id: Int) -> APIRequest<User,MyAppError> {
        let request: APIRequest<User,MyAppError> = tron.codable.request("users/\(id)")
        request.method = .delete
        return request
    }
}
```

Using these requests is really simple:

```swift
Users.read(56).perform(withSuccess: { user in
  print("received user id 56 with name: \(user.name)")
})
```

It can be also nice to introduce namespacing to your API:

```swift
enum API {}
extension API {
  enum Users {
    // ...
  }
}
```

This way you can call your API methods like so:

```swift
API.Users.delete(56).perform(withSuccess: { user in
  print("user \(user) deleted")
})
```

## Stubbing

Stubbing is built right into APIRequest itself. All you need to stub a successful request is to set apiStub property and turn stubbingEnabled on:

```swift
let request = API.Users.get(56)
request.stubbingEnabled = true
request.apiStub.model = User.fixture()

request.perform(withSuccess: { stubbedUser in
  print("received stubbed User model: \(stubbedUser)")
})
```

Stubbing can be enabled globally on `TRON` object or locally for a single `APIRequest`. Stubbing unsuccessful requests is easy as well:

```swift
let request = API.Users.get(56)
request.stubbingEnabled = true
request.apiStub.error = APIError<MyAppError>.fixtureError()
request.perform(withSuccess: { _ in }, failure: { error in
  print("received stubbed api error")
})
```

You can also optionally delay stubbing time or explicitly set that api stub should fail:

```swift
request.apiStub.stubDelay = 1.5
request.apiStub.successful = false
```

## Upload

* From file:

```swift
let request = tron.codable.upload("photo", fromFileAt: fileUrl)
```

* Data:

```swift
let request = tron.codable.upload("photo", data: data)
```

* Stream:

```swift
let request = tron.codable.upload("photo", fromStream: stream)
```

* Multipart-form data:

```swift
let request: UploadAPIRequest<EmptyResponse,MyAppError> = tron.codable.uploadMultipart("form") { formData in
    formData.append(data, withName: "cat", mimeType: "image/jpeg")
}
request.performMultipart(withSuccess: { result in
    print("form sent successfully")
})
```

**Note** Multipart form data uploads use `MultipartAPIRequest` class instead of `APIRequest` and have different perform method.

## Download

```swift
let request = tron.codable.download("file", to: destination)
```

Resume downloads:

```swift
let request = tron.codable.download("file", to: destination, resumingFrom: data)
```

## Plugins

`TRON` includes plugin system, that allows reacting to most of request events.

```swift
public protocol Plugin {
    func willSendRequest<Model,ErrorModel>(_ request: BaseRequest<Model,ErrorModel>)

    func willSendAlamofireRequest<Model,ErrorModel>(_ request: Request, formedFrom tronRequest: BaseRequest<Model,ErrorModel>)

    func didSendAlamofireRequest<Model,ErrorModel>(_ request : Request, formedFrom tronRequest: BaseRequest<Model,ErrorModel>)

    func willProcessResponse<Model,ErrorModel>(response: (URLRequest?, HTTPURLResponse?, Data?, Error?),
                                                forRequest request: Request,
                                                formedFrom tronRequest: BaseRequest<Model,ErrorModel>)

    func didSuccessfullyParseResponse<Model,ErrorModel>(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?),
                                                        creating result: Model,
                                                        forRequest request: Request,
                                                        formedFrom tronRequest: BaseRequest<Model,ErrorModel>)

    func didReceiveError<Model,ErrorModel>(_ error: APIError<ErrorModel>,
                                        forResponse response : (URLRequest?, HTTPURLResponse?, Data?, Error?),
                                        request: Alamofire.Request,
                                        formedFrom tronRequest: BaseRequest<Model,ErrorModel>)

    func didReceiveDataResponse<Model,ErrorModel>(_ response: DataResponse<Model>,
                                        forRequest request: Alamofire.Request,
                                        formedFrom tronRequest: BaseRequest<Model,ErrorModel>)

    func didReceiveDownloadResponse<Model,ErrorModel>(_ response: DownloadResponse<Model>,
                                                    forRequest request: Alamofire.DownloadRequest,
                                                    formedFrom tronRequest: BaseRequest<Model,ErrorModel>)
}
```

Plugins can be used globally, on `TRON` instance itself, or locally, on concrete `APIRequest`. Keep in mind, that plugins that are added to `TRON` instance, will be called for each request. There are some really cool use-cases for global and local plugins.

By default, no plugins are used, however two plugins are implemented as a part of `TRON` framework.

### NetworkActivityPlugin

`NetworkActivityPlugin` serves to monitor requests and control network activity indicator in iPhone status bar. This plugin assumes you have only one `TRON` instance in your application.

```swift
let tron = TRON(baseURL: "https://api.myapp.com", plugins: [NetworkActivityPlugin()])
```

### NetworkLoggerPlugin

`NetworkLoggerPlugin` is used to log responses to console in readable format. By default, it prints only failed requests, skipping requests that were successful.

### Local plugins

There are some very cool concepts for local plugins, some of them are described in dedicated [PluginConcepts](Docs/PluginConcepts.md) page.

## Alternatives

We are dedicated to building best possible tool for interacting with RESTful web-services. However, we understand, that every tool has it's purpose, and therefore it's always useful to know, what other tools can be used to achieve the same goal.

`TRON` was heavily inspired by [Moya framework](https://github.com/Moya/Moya) and [LevelUPSDK](https://github.com/TheLevelUp/levelup-sdk-ios/blob/master/Source/API/Client/LUAPIClient.h)

## License

`TRON` is released under the MIT license. See LICENSE for details.

## About MLSDev

[<img src="https://github.com/MLSDev/development-standards/raw/master/mlsdev-logo.png" alt="MLSDev.com">][mlsdev]

`TRON` is maintained by MLSDev, Inc. We specialize in providing all-in-one solution in mobile and web development. Our team follows Lean principles and works according to agile methodologies to deliver the best results reducing the budget for development and its timeline.

Find out more [here][mlsdev] and don't hesitate to [contact us][contact]!

[mlsdev]: http://mlsdev.com
[contact]: http://mlsdev.com/contact_us
