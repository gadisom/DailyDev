import ProjectDescription

let project = Project(
    name: "Data",
    organizationName: "DailyDev",
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
            name: "Data",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.dailydev.data",
            deploymentTargets: .multiplatform(
                iOS: "18.0",
                macOS: "14.0"
            ),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Core", path: "../Core"),
                .project(target: "Entity", path: "../Entity"),
                .project(target: "Domain", path: "../Domain"),
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
