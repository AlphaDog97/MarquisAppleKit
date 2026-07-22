// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MarquisAppleKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "AppCore", targets: ["AppCore"]),
        .library(name: "AppDesignTokens", targets: ["AppDesignTokens"]),
        .library(name: "AppDesignComponents", targets: ["AppDesignComponents"])
    ],
    targets: [
        .target(name: "AppCore"),
        .target(name: "AppDesignTokens"),
        .target(
            name: "AppDesignComponents",
            dependencies: ["AppCore", "AppDesignTokens"]
        ),
        .testTarget(
            name: "AppCoreTests",
            dependencies: ["AppCore"]
        ),
        .testTarget(
            name: "AppDesignTokensTests",
            dependencies: ["AppDesignTokens"]
        ),
        .testTarget(
            name: "AppDesignComponentsTests",
            dependencies: ["AppDesignComponents"]
        )
    ]
)
