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
    @Published var homeNavigationRequest: HomeNavigationRequest?

    func navigateToSavedConcept(categoryID: String, conceptID: String) {
        homeNavigationRequest = HomeNavigationRequest(
            categoryID: categoryID,
            subcategoryID: conceptID
        )
        selectedTab = .home
    }
}
