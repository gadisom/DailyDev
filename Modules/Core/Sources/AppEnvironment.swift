import Foundation

public struct AppEnvironment: Sendable, Equatable {
    public let appName: String
    public let supportsTabletLayout: Bool

    public init(
        appName: String = "DailyDev",
        supportsTabletLayout: Bool = true
    ) {
        self.appName = appName
        self.supportsTabletLayout = supportsTabletLayout
    }
}
