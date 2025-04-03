// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BullhornSdk",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(name: "BullhornSdk", targets: ["BullhornSdk"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", "5.8.0"..<"5.9.0"),
        .package(url: "https://github.com/evgenyneu/Cosmos.git", from: "25.0.1"),
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.21.0"),
        .package(url: "https://github.com/SwiftKickMobile/SwiftMessages.git", from: "10.0.1"),
    ],
    targets: [
        .target(
            name: "BullhornSdk",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Cosmos", package: "Cosmos"),
                .product(name: "SDWebImage", package: "SDWebImage"),
                .product(name: "SwiftMessages", package: "SwiftMessages"),
            ],
            path: "Sources/BullhornSdk",
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy"),
                .copy("Resources/Bullhorn.xcdatamodeld"),
                .copy("Resources/BullhornSdk.storyboard"),
                .copy("Resources/images/ic_avatar_placeholder.png"),
                .copy("Resources/images/ic_radio_placeholder.png"),
                .copy("Resources/images/ic_list_placeholder.png"),
                .copy("Resources/images/ic_tile_placeholder.png"),
                .copy("Resources/images/ic_downloads_placeholder.png"),
                .copy("Resources/images/ic_connection_lost.png"),
                .copy("Resources/images/carplay-home.png"),
                .copy("Resources/images/carplay-radio.png"),
                .copy("Resources/images/carplay-downloads.png"),
            ]),
    ]
)
