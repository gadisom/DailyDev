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
        )
    ],
    targets: [
        .target(
            name: "DailyDeviOS",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.dailydev.ios",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "DailyDev",
                    "UILaunchScreen": [:]
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
            ]
        )
    ]
)
