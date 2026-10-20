// swift-tools-version: 6.0
// File: Packages/ShiftCore/Package.swift

// 这是 Swift Package Manager 的包配置文件。
import PackageDescription

let package = Package(
    name: "ShiftCore",
    // 支持的最低系统版本（主要在 Windows 测试，但配置需声明）。
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // 对外暴露的库名为 ShiftCore。
        .library(name: "ShiftCore", targets: ["ShiftCore"])
    ],
    targets: [
        // 定义主目标与测试目标。
        .target(name: "ShiftCore"),
        .testTarget(name: "ShiftCoreTests", dependencies: ["ShiftCore"])
    ]
)