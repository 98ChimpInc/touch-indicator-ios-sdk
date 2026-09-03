// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TouchIndicator",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "TouchIndicator",
            targets: ["TouchIndicator"]
        ),
    ],
    // Zero dependencies by design: the package is installed in every app and
    // must never contribute to SPM resolution conflicts.
    targets: [
        .target(
            name: "TouchIndicator",
            path: "Sources/TouchIndicator"
        ),
        .testTarget(
            name: "TouchIndicatorTests",
            dependencies: ["TouchIndicator"],
            path: "Tests/TouchIndicatorTests"
        ),
    ]
)
