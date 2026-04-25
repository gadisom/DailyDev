import SwiftUI
import Features

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
