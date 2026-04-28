public struct CrashReport: Sendable, Equatable {
    public let name: String
    public let reason: String?
    public let properties: [String: AnalyticsValue]

    public init(
        name: String,
        reason: String? = nil,
        properties: [String: AnalyticsValue] = [:]
    ) {
        self.name = name
        self.reason = reason
        self.properties = properties
    }
}
