#if os(iOS)
import ComposableArchitecture
import Entity

@Reducer
struct QuizFeature {
    @ObservableState
    struct State: Equatable {
        enum Phase: Equatable {
            case idle
            case loading
            case content
            case error(String)
        }

        var phase: Phase
        var categories: [QuizCategoryUIModel]
        var hasLoadedInitialData: Bool

        init(
            phase: Phase = .loading,
            categories: [QuizCategoryUIModel] = [],
            hasLoadedInitialData: Bool = false
        ) {
            self.phase = phase
            self.categories = categories
            self.hasLoadedInitialData = hasLoadedInitialData
        }

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.phase == rhs.phase
                && lhs.hasLoadedInitialData == rhs.hasLoadedInitialData
                && lhs.categories.map(\.id) == rhs.categories.map(\.id)
        }
    }

    enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case task
        case refreshTapped
        case categoriesLoaded(Result<[QuizCategoryUIModel], Error>)
    }

    @Dependency(\.quizDataClient) private var quizDataClient

    init() {}

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .task:
                guard !state.hasLoadedInitialData else { return .none }
                state.phase = .loading
                return .run { send in
                    do {
                        let categories = try await quizDataClient.fetchQuizBank()
                        await send(.categoriesLoaded(.success(categories)))
                    } catch {
                        await send(.categoriesLoaded(.failure(error)))
                    }
                }

            case .refreshTapped:
                state.phase = .loading
                return .run { send in
                    do {
                        let categories = try await quizDataClient.fetchQuizBank()
                        await send(.categoriesLoaded(.success(categories)))
                    } catch {
                        await send(.categoriesLoaded(.failure(error)))
                    }
                }

            case .categoriesLoaded(.success(let categories)):
                state.categories = categories
                state.phase = .content
                state.hasLoadedInitialData = true
                return .none

            case .categoriesLoaded(.failure(let error)):
                state.phase = .error(error.localizedDescription)
                return .none
            }
        }
    }
}
#endif
