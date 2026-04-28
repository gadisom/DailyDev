import ComposableArchitecture
import Core

private enum CrashReportingClientKey: DependencyKey {
    static let liveValue = CrashReportingClient.noop
    static let testValue = CrashReportingClient.noop
}

public extension DependencyValues {
    var crashReportingClient: CrashReportingClient {
        get { self[CrashReportingClientKey.self] }
        set { self[CrashReportingClientKey.self] = newValue }
    }
}
