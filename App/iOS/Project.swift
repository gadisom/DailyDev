import ProjectDescription

let project = Project(
    name: "DailyDeviOS",
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
        ),
        .remote(
            url: "https://github.com/pointfreeco/swift-identified-collections",
            requirement: .upToNextMajor(from: "1.1.0")
        )
    ],
    targets: [
        .target(
            name: "DailyDeviOS",
            destinations: [.iPhone, .iPad],
            product: .app,
            productName: "DailyDev",
            bundleId: "com.dailydev.ios",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "DailyDev",
                    "CFBundleName": "DailyDev",
                    "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_sWMT0op09LVNmJpnHYY6wg_ZIy-bHMV",
                    "SUPABASE_ANON_KEY": "",
                    "UILaunchScreen": [:],
                    "ITSAppUsesNonExemptEncryption": false
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
                .package(product: "IdentifiedCollections"),
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "U6NUHA5DNR"
                ]
            )
        )
    ]
)
