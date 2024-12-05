// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "Relay",
    platforms: [
        .iOS(.v14) 
    ],
    products: [
        .library(
            name: "Relay",
            targets: ["Relay"]
        ),
    ],
    targets: [
        .target(
            name: "Relay",
            dependencies: [],
            path: "Relay/Relay/Sources"
        )
    ]
)