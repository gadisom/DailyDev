import SwiftUI
import ComposableArchitecture
import Core
import Features

@main
struct DailyDevMacOSApp: App {
    var body: some Scene {
        WindowGroup {
            HomeScene(
                store: Store(
                    initialState: HomeFeature.State(
                        platform: .macOS,
                        environment: AppEnvironment()
                    )
                ) {
                    HomeFeature()
                }
            )
                .frame(minWidth: 960, minHeight: 640)
        }
    }
}
