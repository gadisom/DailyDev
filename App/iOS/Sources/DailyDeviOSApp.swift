import SwiftUI
import SwiftData
import ComposableArchitecture
import Core
import Features
import DesignSystem

@main
struct DailyDeviOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    @State private var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    } withDependencies: {
        $0.analyticsClient = .live()
        $0.crashReportingClient = .live()
        $0.appUpdateClient = .live()
    }

    init() {
        FirebaseAppConfigurator.configureIfPossible()
    }

    var body: some Scene {
        WindowGroup {
            @Bindable var store = store
            ZStack {
                TabView(selection: $store.selectedTab) {
                    HomeScene(
                        store: store.scope(state: \.home, action: \.home),
                        navigationPath: $store.homeNavigationPath,
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

                if let policy = store.forceUpdatePolicy {
                    ForceUpdateView(policy: policy)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                store.send(.task)
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                store.send(.checkAppUpdate)
            }
        }
        .modelContainer(for: [SavedConcept.self, SavedQuizQuestion.self, SavedPost.self])
    }
}
