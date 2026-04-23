#if os(iOS)
import ComposableArchitecture

@Reducer
public struct SavedFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Tab: String, CaseIterable, Equatable {
            case concepts = "개념"
            case quiz = "퀴즈"
            case posts = "Post"

            public var icon: String {
                switch self {
                case .concepts: return "book.closed"
                case .quiz: return "questionmark.circle"
                case .posts: return "doc.text"
                }
            }
        }

        public var selectedTab: Tab
        public var isFullQuizFlowPresented: Bool
        public var selectedQuestionID: Int?

        public init(
            selectedTab: Tab = .concepts,
            isFullQuizFlowPresented: Bool = false,
            selectedQuestionID: Int? = nil
        ) {
            self.selectedTab = selectedTab
            self.isFullQuizFlowPresented = isFullQuizFlowPresented
            self.selectedQuestionID = selectedQuestionID
        }
    }

    public enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case tabTapped(State.Tab)
        case fullQuizTapped
        case fullQuizDismissed
        case questionTapped(Int)
        case questionDismissed
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .tabTapped(let tab):
                state.selectedTab = tab
                return .none

            case .fullQuizTapped:
                state.selectedQuestionID = nil
                state.isFullQuizFlowPresented = true
                return .none

            case .fullQuizDismissed:
                state.isFullQuizFlowPresented = false
                return .none

            case .questionTapped(let questionID):
                state.isFullQuizFlowPresented = false
                state.selectedQuestionID = questionID
                return .none

            case .questionDismissed:
                state.selectedQuestionID = nil
                return .none
            }
        }
    }
}
#endif
