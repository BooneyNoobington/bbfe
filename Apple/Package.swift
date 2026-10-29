// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BBFE",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "BBFECore", targets: ["BBFECore"]),
        .executable(name: "bbfe", targets: ["bbfe"])
    ],
    targets: [
        .target(name: "BBFECore"),
        .executableTarget(name: "bbfe", dependencies: ["BBFECore"]),
        .testTarget(name: "BBFECoreTests", dependencies: ["BBFECore"], resources: [.copy("Fixtures")])
    ]
)
