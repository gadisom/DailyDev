import SwiftUI
import ComposableArchitecture
import Core
import Features

@main
struct DailyDeviOSApp: App {
    var body: some Scene {
        WindowGroup {
            HomeScene(
                store: Store(
                    initialState: HomeFeature.State(
                        platform: .iOS,
                        environment: AppEnvironment()
                    )
                ) {
                    HomeFeature()
                }
            )
        }
    }
}
