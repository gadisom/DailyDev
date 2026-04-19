import ProjectDescription

let project = Project(
    name: "Entity",
    organizationName: "DailyDev",
    targets: [
        .target(
            name: "Entity",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.dailydev.entity",
            deploymentTargets: .multiplatform(
                iOS: "18.0",
                macOS: "14.0"
            ),
            sources: ["Sources/**"]
        )
    ]
)
