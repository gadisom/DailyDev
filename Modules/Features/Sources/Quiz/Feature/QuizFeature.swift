#if os(iOS)
import ComposableArchitecture
import Entity

@Reducer
public struct QuizFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Phase: Equatable {
            case idle
            case loading
            case content
            case error(String)
        }

        public var phase: Phase
        public var categories: [QuizCategory]
        public var hasLoadedInitialData: Bool

        public init(
            phase: Phase = .loading,
            categories: [QuizCategory] = [],
            hasLoadedInitialData: Bool = false
        ) {
            self.phase = phase
            self.categories = categories
            self.hasLoadedInitialData = hasLoadedInitialData
        }

        public static func == (lhs: State, rhs: State) -> Bool {
            lhs.phase == rhs.phase
                && lhs.hasLoadedInitialData == rhs.hasLoadedInitialData
                && lhs.categories.map(\.id) == rhs.categories.map(\.id)
        }
    }

    public enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case task
        case refreshTapped
        case categoriesLoaded(Result<[QuizCategory], Error>)
    }

    @Dependency(\.quizDataClient) private var quizDataClient

    public init() {}

    public var body: some ReducerOf<Self> {
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
