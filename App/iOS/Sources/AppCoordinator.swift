import ComposableArchitecture
import Core
import Features

@Reducer
struct AppFeature {
    @Dependency(\.analyticsClient) private var analyticsClient

    enum MainTab: Hashable {
        case home
        case quiz
        case post
        case saved
    }

    @ObservableState
    struct State: Equatable {
        var selectedTab: MainTab = .home
        var homeNavigationPath: [HomeRoute] = []
        var homeNavigationRequest: HomeNavigationRequest?
        var didTrackAppOpened = false
        var home: HomeFeature.State
        var quiz: QuizFeature.State
        var post: PostFeature.State
        var saved: SavedFeature.State

        init() {
            home = HomeFeature.State(platform: .iOS, environment: AppEnvironment())
            quiz = QuizFeature.State()
            post = PostFeature.State()
            saved = SavedFeature.State()
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case task
        case home(HomeFeature.Action)
        case quiz(QuizFeature.Action)
        case post(PostFeature.Action)
        case saved(SavedFeature.Action)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.home, action: \.home) { HomeFeature() }
        Scope(state: \.quiz, action: \.quiz) { QuizFeature() }
        Scope(state: \.post, action: \.post) { PostFeature() }
        Scope(state: \.saved, action: \.saved) { SavedFeature() }

        Reduce { state, action in
            switch action {
            case .task:
                guard !state.didTrackAppOpened else {
                    return .none
                }
                state.didTrackAppOpened = true
                return .run { _ in
                    await analyticsClient.track(.appOpened)
                }

            case .binding(\.selectedTab):
                let tabName: String
                switch state.selectedTab {
                case .home:
                    tabName = "home"
                case .quiz:
                    tabName = "quiz"
                case .post:
                    tabName = "post"
                case .saved:
                    tabName = "saved"
                }
                return .run { _ in
                    await analyticsClient.track(.tabSelected(tab: tabName))
                }

            case .saved(.delegate(.selectConcept(let categoryID, let conceptID))):
                state.homeNavigationRequest = HomeNavigationRequest(
                    categoryID: categoryID,
                    subcategoryID: conceptID
                )
                state.selectedTab = .home
                return .none
            default:
                return .none
            }
        }
    }
}
