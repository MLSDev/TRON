# Change Log
All notable changes to this project will be documented in this file.

## Master

### New

* `stubbingShouldBeSuccessful` property on `TRON`, that allows setting up globally, will stubs succeed or not.
* `encodingStrategy` property on `TRON` instance, that is used to select encoding type based on HTTP Method.
* `encodingStrategy` property on `APIRequest`, that will be filled with `TRON` strategy on construction.

By default, for backwards compatibility reasons, we use ParameterEncoding.URL as a default strategy. This will change in next major release of TRON, which will use `TRON.RESTEncodingStrategy` instead. This encoding strategy uses .JSON encoding for POST, PUT and PATCH requests, and .URL encoding for all other HTTP methods.

### Deprecated

* `encoding` property on `APIRequest`. Please use `encodingStrategy` property instead.

## [1.0.0](https://github.com/MLSDev/TRON/releases/tag/1.0.0)

### Changes

None.

If you haven't been following beta releases, please read [1.0.0 Migration Guide](/Docs/1.0 Migration Guide.md) to get an overview of new API additions and phylosophy behind some breaking changes that were made in this release.

## [1.0.0-beta.3](https://github.com/MLSDev/TRON/releases/tag/1.0.0-beta.3)

### Breaking changes

* `ResponseParseable` protocol reworked to only include single initializer instead of associated type `ModelType`. Therefore, all generic methods that previously accepted `Model.ModelType` type now accept `Model` type.
* Removed `performWithSuccess(_:failure:)` method, please use `perform(success:failure:)` method instead.

### Added

* Ability to create APIRequest with Array generic constraint, for example - `APIRequest<[Int],TronError>`

### Changed

* `ResponseParseable` `initWithData:` method is now throwable, allowing parsed models to throw during initialization. When initializer throws, `APIRequest` treats it as a parsing error.

## [1.0.0-beta.2](https://github.com/MLSDev/TRON/releases/tag/1.0.0-beta.2)

### Breaking changes

* `ResponseParseable` protocol now accepts NSData instead of `AnyObject` in its constructor, allowing any kind of parsing, JSON/XML, you-name-it.

## [1.0.0-beta.1](https://github.com/MLSDev/TRON/releases/tag/1.0.0-beta.1)

TRON 1.0 is a major release with a lot of new features and breaking changes. To find out more about philosophy of those and how to adapt to new API's, read [TRON 1.0 Migration Guide](/Docs/1.0 Migration Guide.md)

### Breaking changes

* `RequestToken` protocol removed, perform request methods now return `Alamofire.Request?` to allow customization. When request is stubbed, nil is returned.
* `tron.multipartRequest(path:)` removed, use `tron.uploadMultipart(path:formData:)` method instead
* `MultipartAPIRequest` `performWithSuccess(_:failure:progress:cancellableCallback:)` method is replaced by `performMultipart(success:failure:encodingMemoryThreshold:encodingCompletion:)`
* `MultipartAPIRequest` no longer subclasses `APIRequest` - they both now subclass `BaseRequest`.
* `appendMultipartData(_:name:filename:mimeType:)` on `MultipartAPIRequest` is removed. Please use `Alamofire.Manager.MultipartFormData` built-in methods to append multipart data
* RxSwift extension on `MultipartAPIRequest` reworked to return single Observable<ModelType>
* `EventDispatcher` class and corresponding `TRON.dispatcher`, `APIRequest.dispatcher` property are replaced by `TRON` and `APIRequest` properties - `processingQueue` and `resultDeliveryQueue`, which are used to determine on which queue should processing be performed and on which queue results should be delivered.
* `Progress` and `ProgressClosure` typealiases have been removed

### Added

* `upload(path:file:)` - upload from file
* `upload(path:data:)` - upload data
* `upload(path:stream:)` - upload from stream
* `download(path:destination:)` - download file to destination
* `download(path:destination:resumingFromData:)` - download file to destination, resuming from data
* `uploadMultipart(path:formData:)` - multipart form data upload
* `perform(completion:)` method, that accepts `Alamofire.Response` -> Void block.

### Deprecations

* `APIRequest` `performWithSuccess(_:failure:)` method is deprecated, new name - `perform(success:failure:)`

## [0.4.3](https://github.com/MLSDev/TRON/releases/tag/0.4.3)

### Fixed

* Allow `MultipartAPIRequest` to use any StringLiteralConvertible value in parameters (for example Int, or Bool e.t.c).

## [0.4.2](https://github.com/MLSDev/TRON/releases/tag/0.4.2)

### Fixed

* Prevent `APIRequest` from being deallocated if rxResult Observable is passed elsewhere without keeping strong reference to `APIRequest` itself.

## [0.4.1](https://github.com/MLSDev/TRON/releases/tag/0.4.1)

### Fixed

* Plugins are now correctly notified with "willSendRequest(_:)" method call for multipart requests.

## [0.4.0](https://github.com/MLSDev/TRON/releases/tag/0.4.0)

### Breaking

* Update to Swift 2.2. This release is not backwards compatible with Swift 2.1.
* `NetworkActivityPlugin` now accepts `UIApplication` in it's initializer to be able to compile in application extensions environments.
* `NetworkActivityPlugin` supports only single instance of `TRON`. If you have multiple `TRON`s in your application, consider building another plugin, that uses static variables to track number of requests, similar to old `NetworkActivityPlugin` from `5639b960e968586d1e24a7adcc6a3420e8648d49`.

### Added

* Added `EmptyResponse` class that can be used for requests with empty body. For example:

```swift
let request : APIRequest<EmptyResponse, MyError> = tron.request("empty/response")
```

* RxSwift extensions for `APIRequest` and `MultipartAPIRequest`, usage:

```swift
let request : APIRequest<Foo, MyError> = tron.request("foo")
_ = request.rxResult.subscribeNext { result in
    print(result)
}
```

```swift
let multipartRequest = MultipartAPIRequest<Foo,MyError> = tron.multipartRequest("foo")

let (progress, result) = multipartRequest.rxUpload()

_ = progress.subscribeNext { progress in
    print(progress.bytesSent,progress.totalBytesWritten,progress.totalBytesExpectedToWrite)
}

_ = result.subscribeNext { result in
    print("Received result: \(result)")
}
```

## [0.3.0](https://github.com/MLSDev/TRON/releases/tag/0.3.0)

Completion blocks are now handled by new `EventDispatcher` class, which is responsible for running completion blocks on predefined GCD-queue.

Default behaviour - all parsing is made on QOS_CLASS_USER_INITIATED queue, success and failure blocks are called on main queue.

You can specify `processingQueue`, `successDeliveryQueue` and `failureDeliveryQueue` on `dispatcher` property of TRON. After request creation you can modify queues using `dispatcher` property on APIRequest, or even replace EventDispatcher with a custom one.

## [0.2.1](https://github.com/MLSDev/TRON/releases/tag/0.2.1)

Added public initializer for NetworkActivityPlugin

## [0.2.0](https://github.com/MLSDev/TRON/releases/tag/0.2.0)

Add support for any custom mapper to be used with TRON. Defaulting to `SwiftyJSON`.

Examples:

[Argo](https://github.com/MLSDev/TRON/blob/master/Custom%20mappers/Argo.playground/Contents.swift), [ObjectMapper](https://github.com/MLSDev/TRON/blob/support_custom_mappers/Custom%20mappers/ObjectMapper.playground/Contents.swift)

### Limitations

`ResponseParseable` and `JSONDecodable` are now Self-requirement protocols with all their limitations. Apart from that, there are some other limitations as well:

#### Subclasses

Subclassing ResponseParseable requires explicit typealias in subclassed model:

```swift
class Ancestor: JSONDecodable {
    required init(json: JSON) {

    }
}

class Sibling: Ancestor {
    typealias ModelType = Sibling
}
```

[Discussion in mailing Swift mailing lists](https://lists.swift.org/pipermail/swift-evolution/Week-of-Mon-20151228/004645.html)

#### Multiple custom mappers

Current architecture does not support having more than one mapper in your project, because Swift is unable to differentiate between two ResponseParseable extensions on different types.

#### Arrays and CollectionTypes

Currently, there's no way to extend CollectionType or Array with `JSONDecodable` or `ResponseParseable` protocol, so creating request with ModelType of array(APIRequest<[Foo],Bar>) is not possible.

Blocking radars:
http://www.openradar.me/23433955
http://www.openradar.me/23196859

## [0.1.0](https://github.com/MLSDev/TRON/releases/tag/0.1.0)

Initial OSS release, yaaaay!
