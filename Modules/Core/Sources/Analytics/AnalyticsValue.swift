public enum AnalyticsValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnalyticsValue])
    case object([String: AnalyticsValue])
    case null
}
