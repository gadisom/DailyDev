import SwiftUI
import ComposableArchitecture
import Core
import Features

@main
struct DailyDeviOSApp: App {
    private let homeStore = Store(
        initialState: HomeFeature.State(
            platform: .iOS,
            environment: AppEnvironment()
        )
    ) {
        HomeFeature()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeScene(store: homeStore)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }

                NavigationStack {
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 34))
                            .foregroundStyle(.secondary)
                        Text("Quiz")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                }
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("Quiz")
                }

                NavigationStack {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 34))
                            .foregroundStyle(.secondary)
                        Text("Profile")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                }
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
            }
        }
    }
}
