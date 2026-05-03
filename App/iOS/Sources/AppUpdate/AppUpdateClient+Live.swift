import ComposableArchitecture
import Core

private enum AppUpdateClientKey: DependencyKey {
    static let liveValue = AppUpdateClient.noop
    static let testValue = AppUpdateClient.noop
}

extension DependencyValues {
    var appUpdateClient: AppUpdateClient {
        get { self[AppUpdateClientKey.self] }
        set { self[AppUpdateClientKey.self] = newValue }
    }
}

extension AppUpdateClient {
    static func live() -> AppUpdateClient {
        let service = FirebaseRemoteConfigAppUpdateService()

        return AppUpdateClient(
            requiredUpdatePolicy: {
                try await service.requiredUpdatePolicy()
            }
        )
    }
}
