import AmplitudeSwift
import Core
import Foundation

actor AmplitudeAnalyticsService {
    private let amplitude: Amplitude?

    init(apiKey: String? = nil) {
        if let resolvedAPIKey = Self.resolveAPIKey(explicit: apiKey) {
            amplitude = Amplitude(configuration: Configuration(apiKey: resolvedAPIKey))
        } else {
            amplitude = nil
        }
    }

    func track(_ event: Core.AnalyticsEvent) {
        guard let amplitude else { return }

        if event.properties.isEmpty {
            amplitude.track(eventType: event.name)
            return
        }

        amplitude.track(
            eventType: event.name,
            eventProperties: event.properties.mapValues { $0.foundationValue }
        )
    }

    func setUserID(_ userID: String?) {
        amplitude?.setUserId(userId: userID)
    }

    private static func resolveAPIKey(explicit: String?) -> String? {
        if let explicit, !explicit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return explicit.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "AMPLITUDE_API_KEY") as? String,
           !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let apiKey = ProcessInfo.processInfo.environment["AMPLITUDE_API_KEY"],
           !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }
}

private extension Core.AnalyticsValue {
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
