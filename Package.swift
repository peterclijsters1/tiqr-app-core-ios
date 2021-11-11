// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TiqrCore",
    defaultLocalization: "en",
    products: [
        .library(
            name: "TiqrCore",
            targets: ["TiqrCore"]),
    ],
    targets: [
        .target(
            name: "TiqrCore",
            dependencies: ["TiqrCoreObjC"]),
        .target(
            name: "TiqrCoreObjC",
            resources: [
                .process("Resources/General/Settings.plist"),
                .process("Resources/Audio/cowbell.wav"),
                .process("Resources/Views/HTML/start.html")
            ])
    ]
)
