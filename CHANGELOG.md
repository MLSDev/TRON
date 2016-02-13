# Change Log
All notable changes to this project will be documented in this file.

## [0.2.0](https://github.com/MLSDev/TRON/releases/tag/0.2.0)

Add support for any custom mapper to be used with TRON. Defaulting to `SwiftyJSON`.

Examples:

[Argo](https://github.com/MLSDev/TRON/blob/master/Custom%20mappers/Argo.playground/Contents.swift), [ObjectMapper](https://github.com/MLSDev/TRON/blob/support_custom_mappers/Custom%20mappers/ObjectMapper.playground/Contents.swift)

### Limitations

Currently, there's no way to extend CollectionType or Array with `JSONDecodable` or `ResponseParseable` protocol, so creating request with ModelType of array(APIRequest<[Foo],Bar>) is not possible.

Blocking radars:
http://www.openradar.me/23433955
http://www.openradar.me/23196859

## [0.1.0](https://github.com/MLSDev/TRON/releases/tag/0.1.0)

Initial OSS release, yaaaay!
