// swift-tools-version:5.6

import PackageDescription

#if os(Linux)
let package = Package(
        name: "JyutBot",
        products: [
                .executable(name: "jyutbot", targets: ["JyutBot"])
        ],
        dependencies: [
                .package(url: "https://github.com/ShaneQi/ZEGBot.git", from: "4.2.6"),
                .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
                .package(url: "https://github.com/ososoio/SQLite3.git", from: "1.0.0")
        ],
        targets: [
                .executableTarget(
                        name: "JyutBot",
                        dependencies: [
                                .product(name: "ZEGBot", package: "ZEGBot"),
                                .product(name: "Logging", package: "swift-log"),
                                .product(name: "SQLite3", package: "SQLite3")
                        ]
                ),
                .testTarget(
                        name: "JyutBotTests",
                        dependencies: ["JyutBot"]
                )
        ]
)
#else
let package = Package(
        name: "JyutBot",
        platforms: [.macOS(.v12)],
        products: [
                .executable(name: "jyutbot", targets: ["JyutBot"])
        ],
        dependencies: [
                .package(url: "https://github.com/ShaneQi/ZEGBot.git", from: "4.2.6"),
                .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2")
        ],
        targets: [
                .executableTarget(
                        name: "JyutBot",
                        dependencies: [
                                .product(name: "ZEGBot", package: "ZEGBot"),
                                .product(name: "Logging", package: "swift-log")
                        ]
                ),
                .testTarget(
                        name: "JyutBotTests",
                        dependencies: ["JyutBot"]
                )
        ]
)
#endif
