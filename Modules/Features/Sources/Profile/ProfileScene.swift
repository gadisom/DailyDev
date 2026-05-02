import ComposableArchitecture
import SwiftUI

public struct ProfileScene: View {
    private let store: StoreOf<ProfileFeature>

    public init(store: StoreOf<ProfileFeature>) {
        self.store = store
    }

    public var body: some View {
        #if os(iOS)
        ProfileIOSView(store: store)
        #else
        Text("macOS not supported yet")
        #endif
    }
}
