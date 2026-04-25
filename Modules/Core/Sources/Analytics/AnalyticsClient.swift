public struct AnalyticsClient: Sendable {
    public var track: @Sendable (_ event: AnalyticsEvent) async -> Void
    public var setUserID: @Sendable (_ userID: String?) async -> Void

    public init(
        track: @escaping @Sendable (_ event: AnalyticsEvent) async -> Void,
        setUserID: @escaping @Sendable (_ userID: String?) async -> Void
    ) {
        self.track = track
        self.setUserID = setUserID
    }
}

public extension AnalyticsClient {
    static let noop = AnalyticsClient(
        track: { _ in },
        setUserID: { _ in }
    )

    static func live() -> AnalyticsClient {
        let service = AmplitudeAnalyticsService()

        return AnalyticsClient(
            track: { event in
                await service.track(event)
            },
            setUserID: { userID in
                await service.setUserID(userID)
            }
        )
    }

    func track(
        _ name: String,
        properties: [String: AnalyticsValue] = [:]
    ) async {
        await track(AnalyticsEvent(name: name, properties: properties))
    }
}
