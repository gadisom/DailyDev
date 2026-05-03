public struct AppUpdateClient: Sendable {
    public var requiredUpdatePolicy: @Sendable () async throws -> AppUpdatePolicy?

    public init(
        requiredUpdatePolicy: @escaping @Sendable () async throws -> AppUpdatePolicy?
    ) {
        self.requiredUpdatePolicy = requiredUpdatePolicy
    }
}

public extension AppUpdateClient {
    static let noop = AppUpdateClient(
        requiredUpdatePolicy: { nil }
    )
}
