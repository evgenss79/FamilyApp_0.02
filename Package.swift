// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "FamilyApp",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "FamilyApp", targets: ["FamilyApp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "FamilyApp",
            path: "Sources/FamilyApp"
        )
    ]
)
