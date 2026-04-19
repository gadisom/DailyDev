import ProjectDescription

let project = Project(
    name: "Data",
    organizationName: "DailyDev",
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
            ]
        )
    ]
)
