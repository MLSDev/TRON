// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "TRON",
    platforms: [
        .iOS(.v10),
        .tvOS(.v10),
        .macOS(.v10_12),
        .watchOS(.v3)
    ],
    products: [
        .library(name: "TRON", targets: ["TRON"]),
        .library(name: "TRONSwiftyJSON", targets: ["TRONSwiftyJSON"]),
        .library(name: "RxTRON", targets: ["RxTRON"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: ("5.0.0"))),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.0.0"))
    ],
    targets: [
         .target(
            name: "TRON",
            dependencies: [ "Alamofire" ]),
        .target(
            name: "RxTRON",
            dependencies: [
                "TRON",
                "RxSwift"
            ]),
        .target(
            name: "TRONSwiftyJSON",
            dependencies: [
                "TRON",
                "SwiftyJSON"])
    ]
)
