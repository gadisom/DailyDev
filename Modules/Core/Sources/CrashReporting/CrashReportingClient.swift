public struct CrashReportingClient: Sendable {
    public var log: @Sendable (_ message: String) async -> Void
    public var record: @Sendable (_ report: CrashReport) async -> Void
    public var setUserID: @Sendable (_ userID: String?) async -> Void
    public var setCustomValue: @Sendable (_ value: AnalyticsValue, _ key: String) async -> Void

    public init(
        log: @escaping @Sendable (_ message: String) async -> Void,
        record: @escaping @Sendable (_ report: CrashReport) async -> Void,
        setUserID: @escaping @Sendable (_ userID: String?) async -> Void,
        setCustomValue: @escaping @Sendable (_ value: AnalyticsValue, _ key: String) async -> Void
    ) {
        self.log = log
        self.record = record
        self.setUserID = setUserID
        self.setCustomValue = setCustomValue
    }
}

public extension CrashReportingClient {
    static let noop = CrashReportingClient(
        log: { _ in },
        record: { _ in },
        setUserID: { _ in },
        setCustomValue: { _, _ in }
    )

    func record(
        name: String,
        reason: String? = nil,
        properties: [String: AnalyticsValue] = [:]
    ) async {
        await record(CrashReport(name: name, reason: reason, properties: properties))
    }
}
