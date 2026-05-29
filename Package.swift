// swift-tools-version: 6.0
//
// Run unit tests on macOS without the iOS Simulator:
//   swift test
//
// ViewModel / audio-player tests still run via Xcode (iOS Simulator).

import PackageDescription

let package = Package(
    name: "QuranDailyCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "QuranDailyCore",
            targets: ["QuranDailyCore"]
        ),
    ],
    targets: [
        .target(
            name: "QuranDailyCore",
            path: "QuranDaily",
            exclude: [
                "Assets.xcassets",
                "QuranDailyApp.swift",
                "App/AppContainer.swift",
                "Presentation",
                "Data/Services/AudioPlayerService.swift",
            ]
        ),
        .testTarget(
            name: "QuranDailyCoreTests",
            dependencies: ["QuranDailyCore"],
            path: "QuranDailyTests",
            exclude: [
                "ViewModelTests.swift",
            ]
        ),
    ]
)
