import ProjectDescription

let project = Project(
    name: "DesignSystem",
    organizationName: "DailyDev",
    targets: [
        .target(
            name: "DesignSystem",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.dailydev.designsystem",
            deploymentTargets: .multiplatform(
                iOS: "18.0",
                macOS: "14.0"
            ),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Core", path: "../Core")
            ]
        )
    ]
)
