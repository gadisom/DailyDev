import ComposableArchitecture
import DesignSystem
import SwiftUI

struct ProfileIOSView: View {
    @Bindable var store: StoreOf<ProfileFeature>

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let profile = store.profile {
                profileContent(profile)
            }
        }
        .navigationTitle("Profile")
        .task { store.send(.task) }
    }

    private func profileContent(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(profile.name)
                .font(.title2.bold())
            Text(profile.email)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
