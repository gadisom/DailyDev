import Core

extension AnalyticsClient {
    static func live() -> AnalyticsClient {
        let service = FirebaseAnalyticsService()
        return AnalyticsClient(
            track: { event in await service.track(event) },
            setUserID: { userID in await service.setUserID(userID) }
        )
    }
}
