import ProjectDescription

let project = Project(
    name: "Core",
    organizationName: "DailyDev",
    packages: [
        .remote(
            url: "https://github.com/amplitude/AmplitudeUnified-Swift",
            requirement: .upToNextMinor(from: "0.0.3")
        )
    ],
    settings: .settings(
        base: [
            "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
            "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": "YES",
            "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOL_FRAMEWORKS": "SwiftUI UIKit AppKit",
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES"
        ]
    ),
    targets: [
        .target(
            name: "Core",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.dailydev.core",
            deploymentTargets: .multiplatform(
                iOS: "18.0",
                macOS: "14.0"
            ),
            sources: ["Sources/**"],
            dependencies: [
                .package(product: "AmplitudeUnified")
            ],
            settings: .settings(
                base: [
                    "ENABLE_MODULE_VERIFIER": "YES",
                    "MODULE_VERIFIER_SUPPORTED_LANGUAGES": "objective-c objective-c++",
                    "MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS": "gnu11 gnu++14",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
                    "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": "YES",
                    "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOL_FRAMEWORKS": "SwiftUI UIKit AppKit",
                    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES"
                ]
            )
        )
    ]
)
