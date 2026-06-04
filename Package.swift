// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProcessManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ProcessManager", targets: ["ProcessManager"]),
        .executable(name: "ProcessManagerCheck", targets: ["ProcessManagerCheck"])
    ],
    targets: [
        .target(
            name: "ProcessManagerCore"
        ),
        .executableTarget(
            name: "ProcessManager",
            dependencies: ["ProcessManagerCore"]
        ),
        .executableTarget(
            name: "ProcessManagerCheck",
            dependencies: ["ProcessManagerCore"]
        )
    ]
)
