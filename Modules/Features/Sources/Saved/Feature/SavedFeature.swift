#if os(iOS)
import ComposableArchitecture

@Reducer
public struct SavedFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Tab: String, CaseIterable, Equatable, Sendable {
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
        case delegate(Delegate)

        public enum Delegate: Sendable {
            case selectConcept(categoryID: String, conceptID: String)
        }
    }

    public init() {}

    @Dependency(\.analyticsClient) private var analyticsClient

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .tabTapped(let tab):
                state.selectedTab = tab
                return .run { _ in
                    await analyticsClient.track(.savedTabSelected(tab: tab.rawValue))
                }

            case .fullQuizTapped:
                state.selectedQuestionID = nil
                state.isFullQuizFlowPresented = true
                return .run { _ in
                    await analyticsClient.track(.savedFullQuizStarted)
                }

            case .fullQuizDismissed:
                state.isFullQuizFlowPresented = false
                return .none

            case .questionTapped(let questionID):
                state.isFullQuizFlowPresented = false
                state.selectedQuestionID = questionID
                return .run { _ in
                    await analyticsClient.track(.savedQuizOpened(questionID: questionID))
                }

            case .questionDismissed:
                state.selectedQuestionID = nil
                return .none

            case .delegate(.selectConcept(let categoryID, let conceptID)):
                return .run { _ in
                    await analyticsClient.track(.savedConceptOpened(categoryID: categoryID, conceptID: conceptID))
                }
            }
        }
    }
}
#endif
