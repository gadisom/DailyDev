#if os(iOS)
import ComposableArchitecture
import Entity

@Reducer
struct QuizFlowFeature {

    @ObservableState
    struct State: Equatable {
        var quizSet: QuizSet
        var currentIndex: Int = 0
        var answers: [Int: String] = [:]
        var selectedChoice: Int? = nil
        var selectedOX: String? = nil
        var fillInput: String = ""
        var phase: Phase = .question
        var isDone: Bool = false

        enum Phase: Equatable { case question, explain, result }

        var total: Int { quizSet.questions.count }
        var isLast: Bool { currentIndex == total - 1 }
        var current: QuizQuestion { quizSet.questions[currentIndex] }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case confirmAnswer
        case advanceAfterExplain
        case reset(QuizSet)
        case earlyFinish
        case done
    }

    @Dependency(\.analyticsClient) private var analyticsClient

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
                return .run { _ in
                    await analyticsClient.track(.quizAnswerSubmitted(questionID: q.id, isCorrect: isCorrect))
                }

            case .advanceAfterExplain:
                if state.isLast {
                    if state.total == 1 {
                        state.isDone = true
                    } else {
                        state.phase = .result
                    }
                } else {
                    state.currentIndex += 1
                    state.selectedChoice = nil
                    state.selectedOX = nil
                    state.fillInput = ""
                    state.phase = .question
                }
                return .none

            case let .reset(quizSet):
                state.quizSet = quizSet
                state.currentIndex = 0
                state.answers = [:]
                state.selectedChoice = nil
                state.selectedOX = nil
                state.fillInput = ""
                state.phase = .question
                state.isDone = false
                return .none

            case .earlyFinish:
                state.phase = .result
                return .none

            case .done:
                state.isDone = true
                let correctCount = state.answers.values.filter { $0 == "correct" }.count
                return .run { [total = state.total] _ in
                    await analyticsClient.track(.quizCompleted(totalCount: total, correctCount: correctCount))
                }

            case .binding:
                return .none
            }
        }
    }
}
#endif
