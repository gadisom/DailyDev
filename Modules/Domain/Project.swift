import ProjectDescription

let project = Project(
    name: "Domain",
    organizationName: "DailyDev",
    targets: [
        .target(
            name: "Domain",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.dailydev.domain",
            deploymentTargets: .multiplatform(
                iOS: "18.0",
                macOS: "14.0"
            ),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Entity", path: "../Entity"),
            ]
        )
    ]
)
