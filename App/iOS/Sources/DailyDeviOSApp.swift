import SwiftUI
import SwiftData
import ComposableArchitecture
import Core
import Features
import DesignSystem

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
    private let postStore = Store(
        initialState: PostFeature.State()
    ) {
        PostFeature()
    }
    private let savedStore = Store(
        initialState: SavedFeature.State()
    ) {
        SavedFeature()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeScene(store: homeStore)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }

                QuizScene()
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("Quiz")
                }

                PostScene(store: postStore)
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Post")
                }

                SavedScene(store: savedStore)
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("Saved")
                }
            }
            .accentColor(BrandPalette.green)
            .tint(BrandPalette.green)
        }
        .modelContainer(for: [SavedConcept.self, SavedQuizQuestion.self, SavedPost.self])
    }
}
