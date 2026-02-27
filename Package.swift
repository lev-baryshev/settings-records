// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package: Package = .init(
    name: "SettingsRecords",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "SettingsRecords", targets: ["SettingsRecords"])
    ],
    dependencies: [
        .package(url: "https://github.com/lev-baryshev/storage-solutions.git", exact: Version(1, 1, 0))
    ],
    targets: [
        .target(
            name: "SettingsRecords",
            dependencies: [
                .product(name: "StorageSolutions", package: "storage-solutions")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "SettingsRecordsTests",
            dependencies: ["SettingsRecords"],
            path: "Tests"
        )
    ]
)
