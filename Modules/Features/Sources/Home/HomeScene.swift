import SwiftUI
import ComposableArchitecture

public struct HomeScene: View {
    @Bindable private var store: StoreOf<HomeFeature>
    @Binding private var navigationPath: [HomeRoute]

    public init(
        store: StoreOf<HomeFeature>,
        navigationPath: Binding<[HomeRoute]> = .constant([])
    ) {
        self.store = store
        self._navigationPath = navigationPath
    }

    public var body: some View {
        Group {
            switch store.platform {
            case .iOS:
                HomeIOSCoordinator(store: store, path: $navigationPath)
            case .macOS:
                HomeMacView(store: store)
            }
        }
        .task {
            store.send(.task)
        }
    }
}
