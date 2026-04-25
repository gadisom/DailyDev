import SwiftUI
import SwiftData
import ComposableArchitecture
import Core
import Features
import DesignSystem

@MainActor
final class AppCoordinator: ObservableObject {
    enum MainTab: Hashable {
        case home
        case quiz
        case post
        case saved
    }

    @Published var selectedTab: MainTab = .home
    @Published var homeNavigationPath: [HomeRoute] = []

    func navigateToSavedConcept(categoryID: String, conceptID: String) {
        homeNavigationPath = [
            .category(categoryID),
            .lesson(categoryID: categoryID, subcategoryID: conceptID)
        ]
        selectedTab = .home
    }
}

@main
struct DailyDeviOSApp: App {
    @StateObject private var coordinator = AppCoordinator()

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
            TabView(selection: $coordinator.selectedTab) {
                HomeScene(store: homeStore, navigationPath: $coordinator.homeNavigationPath)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(AppCoordinator.MainTab.home)

                QuizScene()
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("Quiz")
                }
                    .tag(AppCoordinator.MainTab.quiz)

                PostScene(store: postStore)
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Post")
                }
                    .tag(AppCoordinator.MainTab.post)

                SavedScene(
                    store: savedStore,
                    onSelectConcept: coordinator.navigateToSavedConcept(categoryID:conceptID:)
                )
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("Saved")
                }
                    .tag(AppCoordinator.MainTab.saved)
            }
            .accentColor(BrandPalette.green)
            .tint(BrandPalette.green)
        }
        .modelContainer(for: [SavedConcept.self, SavedQuizQuestion.self, SavedPost.self])
    }
}
