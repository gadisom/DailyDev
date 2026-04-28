import Core
import FirebaseCrashlytics
import Foundation

actor FirebaseCrashlyticsService {
    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    func record(_ report: CrashReport) {
        var userInfo = report.properties.mapValues { $0.foundationValue }
        userInfo[NSLocalizedDescriptionKey] = report.name

        if let reason = report.reason {
            userInfo[NSLocalizedFailureReasonErrorKey] = reason
        }

        Crashlytics.crashlytics().record(
            error: NSError(
                domain: "DailyDev.CrashReporting",
                code: 0,
                userInfo: userInfo
            )
        )
    }

    func setUserID(_ userID: String?) {
        Crashlytics.crashlytics().setUserID(userID ?? "")
    }

    func setCustomValue(_ value: AnalyticsValue, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value.foundationValue, forKey: key)
    }
}

private extension AnalyticsValue {
    var foundationValue: Any {
        switch self {
        case let .string(value): value
        case let .int(value): value
        case let .double(value): value
        case let .bool(value): value
        case let .array(values): values.map { $0.foundationValue }
        case let .object(values): values.mapValues { $0.foundationValue }
        case .null: NSNull()
        }
    }
}
