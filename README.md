

<p align="center">
  <img src="TRON.png" />
</p>

![Build Status](https://travis-ci.org/MLSDev/TRON.svg?branch=master) &nbsp;
[![codecov.io](http://codecov.io/github/MLSDev/TRON/coverage.svg?branch=master)](http://codecov.io/github/MLSDev/TRON?branch=master)
![CocoaPod platform](https://cocoapod-badges.herokuapp.com/p/TRON/badge.png) &nbsp;
![CocoaPod version](https://cocoapod-badges.herokuapp.com/v/TRON/badge.png) &nbsp;
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Packagist](https://img.shields.io/packagist/l/doctrine/orm.svg)]()

TRON is a lightweight network abstraction layer, built on top of [Alamofire](https://github.com/Alamofire/Alamofire) and [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON). It can be used to dramatically simplify interacting with RESTful JSON web-services.

## Features

- [x] Generic, protocol-based implementation
- [x] Built-in response and error parsing
- [x] Support for multipart requests
- [x] Robust plugin system
- [x] Stubbing of network requests
- [x] Modular architecture
- [x] Support for iOS/Mac OS X/tvOS/watchOS/Linux
- [x] Support for CocoaPods/Carthage/Swift Package Manager

## Overview

We designed TRON to be simple to use and also very easy to customize. After initial setup, using TRON is very straightforward:

```swift
let request: APIRequest<User,MyAppError> = tron.request(path: "me")
request.performWithSuccess( { user in
  print("Received User: \(user)")
}, failure: { error in
  print("User request failed, parsed error: \(error)")
})
```

## Requirements

- XCode 7
- Swift 2.1+
- iOS 8

## Installation

### CocoaPods

```ruby
pod 'TRON', '~> 0.1.0'
```

### Carthage

```ruby
github "MLSDev/TRON", ~> 0.1
```

## Project status

`TRON` is under active development by MLSDev Inc. Pull requests and issues are welcome!

## Request building

`TRON` object serves as initial configurator for APIRequest, setting all base values and configuring to use with baseURL.

```swift
let tron = TRON(baseURL: "https://api.myapp.com")
```

You need to keep strong reference to `TRON` object, because it holds Alamofire.Manager, that is running all requests.

### NSURLBuildable

`NSURLBuildable` protocol is used to convert relative path to NSURL, that will be used by request.

```swift
public protocol NSURLBuildable {
    func urlForPath(path: String) -> NSURL
}
```

By default, `TRON` uses `URLBuilder` class, that simply appends relative path to base URL, which is sufficient in most cases. You can customize url building process globally by changing `urlBuilder` property on `Tron` or locally, for a single request by modifying `urlBuilder` property on `APIRequest`.

### HeaderBuildable

`HeaderBuildable` protocol is used to configure HTTP headers on your request.

```swift
public protocol HeaderBuildable {
    func headersForAuthorization(requirement: AuthorizationRequirement, headers: [String:String]) -> [String: String]
}
```

`AuthorizationRequirement` is an enum with three values:

```
public enum AuthorizationRequirement {
    case None, Allowed, Required
}
```

It represents scenarios where user is not authorized, user is authorized, but authentication is not required, and a case, where request requires authentication.

By default, `TRON` uses `HeaderBuilder` class, which adds "Accept":"application/json" header to your requests.

## Sending requests

To send APIRequest, call `performWithSuccess(_:, failure:)` method on APIRequest:

```swift
let token = request.performWithSuccess({ result in }, failure: { error in})
```

Notice that `token` variable returned from this method is an instance, that conforms to `RequestToken` protocol, that contains only single method:

```swift
public protocol RequestToken : CustomStringConvertible, CustomDebugStringConvertible {
  func cancel()
}
```

This is done to prevent leaking implementation detail to client of the framework. This can be an instance of `Alamofire.Request`, or `TRON.APIStub`. Also notice, that this protocol inherits from `CustomStringConvertible` and `CustomDebugStringConvertible` protocols, allowing us to use awesome `Alamofire` framework features like printing cURL representation of request into console:

```swift
let token = request.performWithSuccess({ _ in }, failure: { _ in })
debugPrint(token)
```

Output:

```bash
$ curl -i \
	-H "Accept: application/json" \
	-H "Accept-Language: en-US;q=1.0" \
	-H "Accept-Encoding: gzip;q=1.0, compress;q=0.5" \
	-H "User-Agent: Unknown/Unknown (Unknown; OS Version 9.2 (Build 13C75))" \
	"https://github.com/foobar"
```

## Response parsing

Generic APIRequest implementation allows us to define expected response type before request is even sent. It also allows us to setup basic parsing rules, which is where `SwiftyJSON` comes in. We define a simple `JSONDecodable` protocol, that allows us to create models of specific type:

```swift
public protocol JSONDecodable {
    init(json: JSON)
}
```

To parse your response from the server, all you need to do is to create `JSONDecodable` conforming type, for example:

```
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
request.performWithSuccess({ user in
  print("Received user: \(user.name) with id: \(user.id)")
})
```

There are also default implementations of `JSONDecodable` protocol for Swift built-in types like Array, String, Int, Float, Double and Bool, so you can easily do something like this:

```swift
  let request : APIRequest<[User],MyAppError> = tron.request(path: "friends")
  request.performWithSuccess({ users in
    print("received \(users.count) friends")
  })
```

### Error handling

`TRON` includes built-in parsing for errors by assuming, that error can also be parsed as `JSONDecodable` instance. `APIError` is a generic class, that includes several default properties, that can be fetched from unsuccessful request:

```
struct APIError<T:JSONDecodable> {
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
request.performWithSuccess({ response in }, failure: { error in
    print(error.request) // Original NSURLRequest
    print(error.response) // NSHTTPURLResponse
    print(error.data) // NSData of response
    print(error.error) // NSError from Foundation Loading system
    print(error.errors) // MyAppError parsed property
  })
```

## CRUD

```swift
class UserRequestFactory
{
    static let tron = TRON(baseURL: "https://api.myapp.com")

    class func create() -> APIRequest<User,MyAppError> {
        let request: APIRequest<User,MyAppError> = tron.request(path: "users")
        request.method = .POST
        return request
    }

    class func read(id: Int) -> APIRequest<User, MyAppError> {
        return tron.request(path: "users/\(id)")
    }

    class func update(id: Int, parameters: [String:AnyObject]) -> APIRequest<User, MyAppError> {
        let request: APIRequest<User,MyAppError> = tron.request(path: "users/\(id)")
        request.method = .PUT
        request.parameters = parameters
        return request
    }

    class func delete(id: Int) -> APIRequest<User,MyAppError> {
        let request: APIRequest<User,MyAppError> = tron.request(path: "users/\(id)")
        request.method = .DELETE
        return request
    }
}
```

Using these requests is really simple:

```swift
UserRequestFactory.read(56).performWithSuccess({ user in
  print("received user id 56 with name: \(user.name)")
})
```

It can be also nice to introduce namespacing to your API:

```swift
struct API {}
extension API {
  class User {
    // ...
  }
}
```

This way you can call your API methods like so:

```swift
API.User.delete(56).performWithSuccess({ user in
  print("user \(user) deleted")
})
```

## Stubbing

Stubbing is built right into APIRequest itself. All you need to stub a successful request is to set apiStub property and turn stubbingEnabled on:

```swift
let request = API.User.get(56)
request.stubbingEnabled = true
request.apiStub.model = User.fixture()

request.performWithSuccess({ stubbedUser in
  print("received stubbed User model: \(stubbedUser)")
})
```

Stubbing can be enabled globally on `TRON` object or locally for a single APIRequest. Stubbing unsuccessful requests is easy as well:

```swift
let request = API.User.get(56)
request.stubbingEnabled = true
request.apiStub.error = APIError<MyAppError>.fixtureError()
request.performWithSuccess({ _ in }, failure: { error in
  print("received stubbed api error")
})
```

You can also optionally delay stubbing time or explicitly set that api stub should fail:

```swift
request.apiStub.stubDelay = 1.5
request.apiStub.successful = false
```

## Multipart requests

Multipart requests are implemented using `APIRequest` subclass - `MultipartAPIRequest`. It uses the same set of API's with several additions.

Create multipart request using tron:

```swift
let multipartRequest = tron.multipartRequest(path: "profile")
```

Append multipart-form data:

```
multipartRequest.appendMultipartData(data, name: "avatar", filename: "avatar.jpg", mimeType: "image/jpg")
```

Then, instead of usual `performWithSuccess(_:,failure:)` method, use `performWithSuccess(_:, failure:, progress:,cancellableCallback:)` method:

```
multipartRequest.performWithSuccess({ user in
    print("user avatar updated!")
  },
  failure: { error in
    print("failed to upload user avatar")
  },
  progress: { progress in
    print("Picture is uploading, progress: \(CGFloat(progress.totalBytesWritten) / CGFloat(progress.totalBytesExpectedToWrite))")
  })
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

There are also alternative JSON mappers available, such as [Argo](https://github.com/thoughtbot/Argo)

## License

`TRON` is released under the MIT license. See LICENSE for details.

## About MLSDev

[<img src="https://github.com/MLSDev/development-standards/raw/master/mlsdev-logo.png" alt="MLSDev.com">][mlsdev]

`TRON` is maintained by MLSDev, Inc. We specialize in providing all-in-one solution in mobile and web development. Our team follows Lean principles and works according to agile methodologies to deliver the best results reducing the budget for development and its timeline.

Find out more [here][mlsdev] and don't hesitate to [contact us][contact]!

[mlsdev]: http://mlsdev.com
[contact]: http://mlsdev.com/contact_us
