#if !os(iOS)
import SwiftUI
import ComposableArchitecture

struct HomeIOSCoordinator: View {
    let store: StoreOf<HomeFeature>

    var body: some View {
        EmptyView()
    }
}

struct HomeIOSContainer: View {
    let store: StoreOf<HomeFeature>

    var body: some View {
        EmptyView()
    }
}
#endif
