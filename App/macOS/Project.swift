import ProjectDescription

let project = Project(
    name: "DailyDevMacOS",
    organizationName: "DailyDev",
    packages: [
        .remote(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            requirement: .upToNextMajor(from: "1.25.0")
        ),
        .remote(
            url: "https://github.com/pointfreeco/swift-dependencies",
            requirement: .upToNextMajor(from: "1.12.0")
        ),
        .remote(
            url: "https://github.com/pointfreeco/swift-case-paths",
            requirement: .upToNextMajor(from: "1.7.0")
        )
    ],
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "U6NUHA5DNR",
            "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
            "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": "YES",
            "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOL_FRAMEWORKS": "SwiftUI AppKit",
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES"
        ]
    ),
    targets: [
        .target(
            name: "DailyDevMacOS",
            destinations: .macOS,
            product: .app,
            bundleId: "com.dailydev.macos",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "DailyDev",
                    "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_sWMT0op09LVNmJpnHYY6wg_ZIy-bHMV",
                    "SUPABASE_ANON_KEY": ""
                ]
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "Core", path: "../../Modules/Core"),
                .project(target: "DesignSystem", path: "../../Modules/DesignSystem"),
                .project(target: "Features", path: "../../Modules/Features"),
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
                .package(product: "CasePaths"),
                ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
                    "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": "YES",
                    "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOL_FRAMEWORKS": "SwiftUI AppKit",
                    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES"
                ]
            )
        )
    ]
)
