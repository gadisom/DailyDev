import ProjectDescription

let project = Project(
    name: "Features",
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
            url: "https://github.com/pointfreeco/swift-perception",
            requirement: .upToNextMajor(from: "2.0.0")
        ),
        .remote(
            url: "https://github.com/pointfreeco/swift-identified-collections",
            requirement: .upToNextMajor(from: "1.1.0")
        )
    ],
    targets: [
        .target(
            name: "Features",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.dailydev.features",
            deploymentTargets: .multiplatform(
                iOS: "18.0",
                macOS: "14.0"
            ),
            infoPlist: .file(path: "Support/Features-Info.plist"),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Core", path: "../Core"),
                .project(target: "Data", path: "../Data"),
                .project(target: "DesignSystem", path: "../DesignSystem"),
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Entity", path: "../Entity"),
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
                .package(product: "CasePaths"),
                .package(product: "Perception"),
                .package(product: "IdentifiedCollections"),
            ]
        )
    ]
)
