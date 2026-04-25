import SwiftUI
import SwiftData
import ComposableArchitecture
import Core
import Features
import DesignSystem

@main
struct DailyDeviOSApp: App {
    @State private var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            @Bindable var store = store
            TabView(selection: $store.selectedTab) {
                HomeScene(
                    store: store.scope(state: \.home, action: \.home),
                    navigationRequest: $store.homeNavigationRequest
                )
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(AppFeature.MainTab.home)

                QuizScene(store: store.scope(state: \.quiz, action: \.quiz))
                    .tabItem {
                        Image(systemName: "questionmark.circle")
                        Text("Quiz")
                    }
                    .tag(AppFeature.MainTab.quiz)

                PostScene(store: store.scope(state: \.post, action: \.post))
                    .tabItem {
                        Image(systemName: "doc.text")
                        Text("Post")
                    }
                    .tag(AppFeature.MainTab.post)

                SavedScene(store: store.scope(state: \.saved, action: \.saved))
                    .tabItem {
                        Image(systemName: "bookmark.fill")
                        Text("Saved")
                    }
                    .tag(AppFeature.MainTab.saved)
            }
            .accentColor(BrandPalette.green)
            .tint(BrandPalette.green)
        }
        .modelContainer(for: [SavedConcept.self, SavedQuizQuestion.self, SavedPost.self])
    }
}
