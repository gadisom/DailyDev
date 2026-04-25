import SwiftUI
import SwiftData
import ComposableArchitecture
import Core
import Features
import DesignSystem

@main
struct DailyDeviOSApp: App {
    private enum MainTab: Hashable {
        case home
        case quiz
        case post
        case saved
    }

    @State private var selectedTab: MainTab = .home
    @State private var homeNavigationPath: [HomeRoute] = []

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
            TabView(selection: $selectedTab) {
                HomeScene(store: homeStore, navigationPath: $homeNavigationPath)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(MainTab.home)

                QuizScene()
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("Quiz")
                }
                .tag(MainTab.quiz)

                PostScene(store: postStore)
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Post")
                }
                .tag(MainTab.post)

                SavedScene(
                    store: savedStore,
                    onSelectConcept: handleSelectSavedConcept(categoryID:conceptID:)
                )
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("Saved")
                }
                .tag(MainTab.saved)
            }
            .accentColor(BrandPalette.green)
            .tint(BrandPalette.green)
        }
        .modelContainer(for: [SavedConcept.self, SavedQuizQuestion.self, SavedPost.self])
    }

    private func handleSelectSavedConcept(categoryID: String, conceptID: String) {
        homeNavigationPath = [
            .category(categoryID),
            .lesson(categoryID: categoryID, subcategoryID: conceptID)
        ]
        selectedTab = .home
    }
}
