import Core
import FirebaseAnalytics
import Foundation

actor FirebaseAnalyticsService {
    func track(_ event: AnalyticsEvent) {
        let params: [String: Any]? = event.properties.isEmpty ? nil :
            event.properties.reduce(into: [:]) { $0[$1.key] = $1.value.firebaseValue }
        Analytics.logEvent(event.name, parameters: params)
    }

    func setUserID(_ userID: String?) {
        Analytics.setUserID(userID)
    }
}

private extension Core.AnalyticsValue {
    var firebaseValue: Any {
        switch self {
        case let .string(v): return v
        case let .int(v): return v
        case let .double(v): return v
        case let .bool(v): return v ? "true" : "false"
        case let .array(vs): return vs.map { $0.firebaseValue }
        case let .object(kvs): return kvs.mapValues { $0.firebaseValue }
        case .null: return ""
        }
    }
}
