import ProjectDescription

let project = Project(
    name: "Core",
    organizationName: "DailyDev",
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
            sources: ["Sources/**"]
        )
    ]
)
