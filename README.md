

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
- [x] Support for any custom mapper. Defaults to [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON).
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
let request: APIRequest<User,MyAppError> = tron.request(path: "me")
request.perform(success: { user in
  print("Received User: \(user)")
}, failure: { error in
  print("User request failed, parsed error: \(error)")
})
```

## Requirements

- XCode 7.3
- Swift 2.2
- iOS 8

## Installation

### CocoaPods

```ruby
pod 'TRON', '~> 1.1.0'
```

Only Core subspec, without SwiftyJSON dependency:

```ruby
pod 'TRON/Core', '~> 1.1.0'
```

RxSwift extension for TRON:

```ruby
pod 'TRON/RxSwift', '~> 1.1.0'
```

### Carthages

```ruby
github "MLSDev/TRON", ~> 1.1.0
```

## Project status

`TRON` is under active development by MLSDev Inc. Pull requests and issues are welcome!

## Request building

`TRON` object serves as initial configurator for APIRequest, setting all base values and configuring to use with baseURL.

```swift
let tron = TRON(baseURL: "https://api.myapp.com/")
```

You need to keep strong reference to `TRON` object, because it holds Alamofire.Manager, that is running all requests.

### NSURLBuildable

`NSURLBuildable` protocol is used to convert relative path to NSURL, that will be used by request.

```swift
public protocol NSURLBuildable {
    func urlForPath(path: String) -> NSURL
}
```

By default, `TRON` uses `URLBuilder` class, that simply appends relative path to base URL, which is sufficient in most cases. You can customize url building process globally by changing `urlBuilder` property on `TRON` or locally, for a single request by modifying `urlBuilder` property on `APIRequest`.

### HeaderBuildable

`HeaderBuildable` protocol is used to configure HTTP headers on your request.

```swift
public protocol HeaderBuildable {
    func headersForAuthorization(requirement: AuthorizationRequirement, headers: [String:String]) -> [String: String]
}
```

`AuthorizationRequirement` is an enum with three values:

```swift
public enum AuthorizationRequirement {
    case None, Allowed, Required
}
```

It represents scenarios where user is not authorized, user is authorized, but authorization is not required, and a case, where request requires authorization.

By default, `TRON` uses `HeaderBuilder` class, which adds "Accept":"application/json" header to your requests.

## Sending requests

To send `APIRequest`, call `perform(success:failure:)` method on `APIRequest`:

```swift
let alamofireRequest = request.perform(success: { result in }, failure: { error in})
```

Notice that `alamofireRequest` variable returned from this method is an Alamofire.Request?, that will be nil if request is stubbed.

Alternatively, you can use `perform(completion:)` method that contains `Alamofire.Response` inside completion closure:

```swift
request.perform(completion: { response in
    print(response.timeline)
    print(response.result)
})
```

In both cases, you can additionally chain `Alamofire.Request` methods, if you need:

```swift
request.perform(success: { result in }, failure: { error in })?.progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
    print(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
}
```

## Response parsing

Generic `APIRequest` implementation allows us to define expected response type before request is even sent. It also allows us to setup basic parsing rules, which is where `ResponseParseable` protocol comes in.

```swift
public protocol ResponseParseable {
    init(data: NSData) throws
}
```

As you can see, protocol accepts NSData in initializer, which means anything can be parsed - JSON, or XML or something else.

`TRON` also provides `JSONDecodable` protocol, that allows us to parse models using SwiftyJSON:

```swift
public protocol JSONDecodable: ResponseParseable {
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
let request: APIRequest<User,MyAppError> = tron.request(path: "me")
request.perform(success: { user in
  print("Received user: \(user.name) with id: \(user.id)")
})
```

There are also default implementations of `JSONDecodable` protocol for Swift built-in types like Array, String, Int, Float, Double and Bool, so you can easily do something like this:

```swift
let request : APIRequest<String,MyAppError> = tron.request(path: "status")
request.perform(success: { status in
    print("Server status: \(status)") //
})
```

You can also use `EmptyResponse` struct in cases where you don't care about actual response.

## Custom mappers

All generic constraints on TRON accept `ResponseParseable` protocol, that can be easily implemented for your mapper.

We are providing code examples on how to do this with two most mappers available in Swift - Unbox and ObjectMapper.

[Playground with Unbox ResponseParseable implementation](https://github.com/MLSDev/TRON/blob/master/Custom%20mappers/Unbox.playground/Contents.swift)

[Playground with ObjectMapper ResponseParseable implementation](https://github.com/MLSDev/TRON/blob/master/Custom%20mappers/ObjectMapper.playground/Contents.swift)

## RxSwift

```swift
let request : APIRequest<Foo, MyError> = tron.request(path: "foo")
_ = request.rxResult.subscribeNext { result in
    print(result)
}
```

```swift
let multipartRequest : APIRequest<Foo,MyError> = tron.upload(path: "foo", formData: { _ in })
multipartRequest.rxMultipartResult().subscribeNext { result in
    print(result)
}
```

### Error handling

`TRON` includes built-in parsing for errors by assuming, that error can also be parsed as `ResponseParseable` instance. `APIError` is a generic class, that includes several default properties, that can be fetched from unsuccessful request:

```swift
struct APIError<T:ResponseParseable> {
    public let request : NSURLRequest?
    public let response : NSHTTPURLResponse?
    public let data : NSData?
    public let error : NSError?

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
request.perform(success: { response in }, failure: { error in
    print(error.request) // Original NSURLRequest
    print(error.response) // NSHTTPURLResponse
    print(error.data) // NSData of response
    print(error.error) // NSError from Foundation Loading system
    print(error.errors) // MyAppError parsed property
  })
```

## CRUD

```swift
struct Users
{
    static let tron = TRON(baseURL: "https://api.myapp.com")

    static func create() -> APIRequest<User,MyAppError> {
        let request: APIRequest<User,MyAppError> = tron.request(path: "users")
        request.method = .post
        return request
    }

    static func read(id: Int) -> APIRequest<User, MyAppError> {
        return tron.request(path: "users/\(id)")
    }

    static func update(id: Int, parameters: [String:AnyObject]) -> APIRequest<User, MyAppError> {
        let request: APIRequest<User,MyAppError> = tron.request(path: "users/\(id)")
        request.method = .PUT
        request.parameters = parameters
        return request
    }

    static func delete(id: Int) -> APIRequest<User,MyAppError> {
        let request: APIRequest<User,MyAppError> = tron.request(path: "users/\(id)")
        request.method = .DELETE
        return request
    }
}
```

Using these requests is really simple:

```swift
Users.read(56).perform(success: { user in
  print("received user id 56 with name: \(user.name)")
})
```

It can be also nice to introduce namespacing to your API:

```swift
struct API {}
extension API {
  struct Users {
    // ...
  }
}
```

This way you can call your API methods like so:

```swift
API.Users.delete(56).perform(success: { user in
  print("user \(user) deleted")
})
```

## Stubbing

Stubbing is built right into APIRequest itself. All you need to stub a successful request is to set apiStub property and turn stubbingEnabled on:

```swift
let request = API.Users.get(56)
request.stubbingEnabled = true
request.apiStub.model = User.fixture()

request.perform(success: { stubbedUser in
  print("received stubbed User model: \(stubbedUser)")
})
```

Stubbing can be enabled globally on `TRON` object or locally for a single `APIRequest`. Stubbing unsuccessful requests is easy as well:

```swift
let request = API.Users.get(56)
request.stubbingEnabled = true
request.apiStub.error = APIError<MyAppError>.fixtureError()
request.perform(success: { _ in }, failure: { error in
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
let request = tron.upload(path: "photo", file: fileUrl)
```

* NSData:

```swift
let request = tron.upload(path: "photo", data: data)
```

* Stream:

```swift
let request = tron.upload(path: "photo", stream: stream)
```

* Multipart-form data:

```swift
let request: MultipartAPIRequest<EmptyResponse,MyAppError> = tron.uploadMultipart(path: "form") { formData in
    formData.appendBodyPart(data: data,name: "cat", mimeType: "image/jpeg")
}
request.performMultipart(success: { result in
    print("form sent successfully")
})
```

**Note** Multipart form data uploads use `MultipartAPIRequest` class instead of `APIRequest` and have different perform method.

## Download

```swift
let request = tron.download(path: "file", destination: destination)
```

Resume downloads:

```swift
let request = tron.download(path: "file", destination: destination, resumingFromData: data)
```

## Plugins

`TRON` includes simple plugin system, that allows reacting to some request events.

```swift
public protocol Plugin {
    func willSendRequest(request: NSURLRequest?)    
    func requestDidReceiveResponse(response: (NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?))
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
