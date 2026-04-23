#if os(iOS)
import ComposableArchitecture
import Entity

@Reducer
public struct QuizFlowFeature {

    @ObservableState
    public struct State: Equatable {
        let quizSet: QuizSet
        var currentIndex: Int = 0
        var answers: [Int: String] = [:]
        var selectedChoice: Int? = nil
        var selectedOX: String? = nil
        var fillInput: String = ""
        var phase: Phase = .question
        var showWrongNotes: Bool = false
        var isDone: Bool = false

        public enum Phase: Equatable { case question, explain, result }

        var total: Int { quizSet.questions.count }
        var isLast: Bool { currentIndex == total - 1 }
        var current: QuizQuestion { quizSet.questions[currentIndex] }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case confirmAnswer
        case advanceAfterExplain
        case earlyFinish
        case retryWrong
        case done
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {

            case .confirmAnswer:
                let q = state.current
                let isCorrect: Bool
                switch q.type {
                case .mcq:  isCorrect = state.selectedChoice == q.correctIndex
                case .ox:   isCorrect = state.selectedOX == q.oxAnswer
                case .fill: isCorrect = state.fillInput
                                .trimmingCharacters(in: .whitespaces)
                                .lowercased() == q.fillAnswer.lowercased()
                }
                state.answers[q.id] = isCorrect ? "correct" : "wrong"
                state.phase = .explain
                return .none

            case .advanceAfterExplain:
                if state.isLast {
                    if state.total == 1 { state.isDone = true } else { state.phase = .result }
                } else {
                    state.currentIndex += 1
                    state.selectedChoice = nil
                    state.selectedOX = nil
                    state.fillInput = ""
                    state.phase = .question
                }
                return .none

            case .earlyFinish:
                state.phase = .result
                return .none

            case .retryWrong:
                state.showWrongNotes = true
                return .none

            case .done:
                state.isDone = true
                return .none

            case .binding:
                return .none
            }
        }
    }
}
#endif
