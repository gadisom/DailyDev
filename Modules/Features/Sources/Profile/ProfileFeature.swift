import ComposableArchitecture
import Core

@Reducer
public struct ProfileFeature {
    @Dependency(\.profileClient) private var profileClient
    @Dependency(\.analyticsClient) private var analyticsClient

    @ObservableState
    public struct State: Equatable {
        public var profile: UserProfile?
        public var isLoading = false

        public init() {}
    }

    public enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case task
        case _profileResponse(Result<UserProfile, Error>)
        case delegate(Delegate)

        public enum Delegate: Sendable {
            case profileLoaded(UserProfile)
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .run { send in
                    do {
                        let profile = try await profileClient.fetchProfile()
                        await send(._profileResponse(.success(profile)))
                    } catch {
                        await send(._profileResponse(.failure(error)))
                    }
                }

            case ._profileResponse(.success(let profile)):
                state.isLoading = false
                state.profile = profile
                return .run { _ in
                    await analyticsClient.track(.profileViewed)
                }

            case ._profileResponse(.failure):
                state.isLoading = false
                return .none

            case .delegate:
                return .none

            case .binding:
                return .none
            }
        }
    }
}
