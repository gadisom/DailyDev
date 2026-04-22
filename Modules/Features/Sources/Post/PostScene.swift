import ComposableArchitecture
import SwiftUI

public struct PostScene: View {
    @Bindable private var store: StoreOf<PostFeature>

    public init(store: StoreOf<PostFeature>) {
        self.store = store
    }

    public var body: some View {
        PostView(store: store)
            .task {
                store.send(.task)
            }
    }
}
