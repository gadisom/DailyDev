import SwiftUI
import ComposableArchitecture

public struct HomeScene: View {
    @Bindable private var store: StoreOf<HomeFeature>

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            switch store.platform {
            case .iOS:
                HomeIOSCoordinator(store: store)
            case .macOS:
                HomeMacView(store: store)
            }
        }
        .task {
            store.send(.task)
        }
    }
}
