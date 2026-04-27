import ComposableArchitecture
import Core

private enum AnalyticsClientKey: DependencyKey {
    static let liveValue = AnalyticsClient.noop
    static let testValue = AnalyticsClient.noop
}

public extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClientKey.self] }
        set { self[AnalyticsClientKey.self] = newValue }
    }
}
