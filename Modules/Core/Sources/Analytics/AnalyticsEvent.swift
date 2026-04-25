public struct AnalyticsEvent: Sendable, Equatable {
    public let name: String
    public let properties: [String: AnalyticsValue]

    public init(
        name: String,
        properties: [String: AnalyticsValue] = [:]
    ) {
        self.name = name
        self.properties = properties
    }
}
