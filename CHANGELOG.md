# Change Log
All notable changes to this project will be documented in this file.

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
