import Core
import FirebaseCore
import FirebaseRemoteConfig
import Foundation

actor FirebaseRemoteConfigAppUpdateService {
    private enum Key {
        static let minimumVersion = "iOS_minimum_version"
        static let updateURL = "iOS_update_url"
        static let message = "iOS_update_message"
    }

    private var remoteConfig: RemoteConfig?

    func requiredUpdatePolicy() async throws -> AppUpdatePolicy? {
        guard FirebaseApp.app() != nil else {
            return nil
        }

        let remoteConfig = configuredRemoteConfig()
        _ = try await remoteConfig.fetchAndActivate()

        let minimumVersionValue = remoteConfig.configValue(forKey: Key.minimumVersion).stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let minimumVersion = minimumVersionValue.isEmpty ? "1.0.0" : minimumVersionValue
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"

        guard AppVersionComparator.isVersion(currentVersion, lowerThan: minimumVersion) else {
            return nil
        }

        let message = remoteConfig.configValue(forKey: Key.message).stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let updateURLString = remoteConfig.configValue(forKey: Key.updateURL).stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return AppUpdatePolicy(
            minimumVersion: minimumVersion,
            currentVersion: currentVersion,
            updateURL: updateURL(from: updateURLString),
            message: !message.isEmpty
                ? message
                : "안정적인 이용을 위해 최신 버전 업데이트가 필요합니다."
        )
    }

    private func updateURL(from string: String?) -> URL? {
        guard let string, !string.isEmpty else {
            return URL(string: "https://apps.apple.com/us/app/dailydev/id6762637987")
        }
        return URL(string: string)
    }

    private func configuredRemoteConfig() -> RemoteConfig {
        if let remoteConfig {
            return remoteConfig
        }

        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 60 * 60
        #endif
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults([
            Key.minimumVersion: "1.0.0" as NSObject,
            Key.updateURL: "" as NSObject,
            Key.message: "안정적인 이용을 위해 최신 버전 업데이트가 필요합니다." as NSObject
        ])
        self.remoteConfig = remoteConfig
        return remoteConfig
    }
}
