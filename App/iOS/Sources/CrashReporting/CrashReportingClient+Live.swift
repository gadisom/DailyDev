import Core

extension CrashReportingClient {
    static func live() -> CrashReportingClient {
        let service = FirebaseCrashlyticsService()

        return CrashReportingClient(
            log: { message in
                await service.log(message)
            },
            record: { report in
                await service.record(report)
            },
            setUserID: { userID in
                await service.setUserID(userID)
            },
            setCustomValue: { value, key in
                await service.setCustomValue(value, forKey: key)
            }
        )
    }
}
