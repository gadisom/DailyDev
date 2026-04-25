import SwiftUI
import ComposableArchitecture

public struct HomeScene: View {
    @Bindable private var store: StoreOf<HomeFeature>
    @Binding private var navigationPath: [HomeRoute]
    @Binding private var navigationRequest: HomeNavigationRequest?

    public init(
        store: StoreOf<HomeFeature>,
        navigationPath: Binding<[HomeRoute]> = .constant([]),
        navigationRequest: Binding<HomeNavigationRequest?> = .constant(nil)
    ) {
        self.store = store
        self._navigationPath = navigationPath
        self._navigationRequest = navigationRequest
    }

    public var body: some View {
        Group {
            switch store.platform {
            case .iOS:
                HomeIOSCoordinator(
                    store: store,
                    path: $navigationPath,
                    navigationRequest: $navigationRequest
                )
            case .macOS:
                HomeMacView(store: store)
            }
        }
        .task {
            store.send(.task)
        }
    }
}
