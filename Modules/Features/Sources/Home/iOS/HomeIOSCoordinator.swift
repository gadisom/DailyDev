#if os(iOS)
import SwiftUI
import ComposableArchitecture
import DesignSystem
import Entity

private enum HomeIOSRoute: Hashable {
    case category(String)
    case lesson(categoryID: String, subcategoryID: String)
}

struct HomeIOSCoordinator: View {
    @Bindable var store: StoreOf<HomeFeature>
    @State private var path: [HomeIOSRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeIOSContainer(store: store) { categoryID in
                if store.selectedCategoryID != categoryID {
                    store.send(.categorySelected(categoryID))
                }
                path.append(.category(categoryID))
            }
            .navigationDestination(for: HomeIOSRoute.self) { route in
                switch route {
                case let .category(categoryID):
                    HomeTopicDetailView(store: store, categoryID: categoryID) { subcategoryID in
                        path.append(.lesson(categoryID: categoryID, subcategoryID: subcategoryID))
                    }
                case let .lesson(categoryID, subcategoryID):
                    HomeLessonDetailView(
                        store: store,
                        categoryID: categoryID,
                        subcategoryID: subcategoryID
                    ) { nextSubcategoryID in
                        path.append(.lesson(categoryID: categoryID, subcategoryID: nextSubcategoryID))
                    }
                }
            }
        }
    }
}
#endif
