#if os(iOS)
import SwiftUI
import ComposableArchitecture
import DesignSystem
import Entity

// MARK: - Flow coordinator

struct QuizFlowView: View {
    @State private var store: StoreOf<QuizFlowFeature>
    let quizSet: QuizSet
    @Environment(\.dismiss) private var dismiss

    init(quizSet: QuizSet) {
        self.quizSet = quizSet
        _store = State(wrappedValue: Store(
            initialState: QuizFlowFeature.State(quizSet: quizSet)
        ) { QuizFlowFeature() })
    }

    var body: some View {
        @Bindable var store = store

        ZStack {
            BrandPalette.background.ignoresSafeArea()

            switch store.phase {
            case .question:
                QuizQuestionView(
                    question: store.current,
                    quizSet: store.quizSet,
                    answers: store.answers,
                    index: store.currentIndex,
                    total: store.total,
                    categoryName: store.quizSet.chapter,
                    selectedChoices: $store.selectedChoices,
                    selectedOX: $store.selectedOX,
                    fillInput: $store.fillInput,
                    onConfirm: { store.send(.confirmAnswer) }
                )
            case .explain:
                QuizExplainView(
                    question: store.current,
                    quizSet: store.quizSet,
                    answers: store.answers,
                    userAnswer: store.answers[store.current.id],
                    index: store.currentIndex,
                    total: store.total,
                    categoryName: store.quizSet.chapter,
                    allowsEarlyExit: store.quizSet.allowsEarlyExit,
                    onNext: { store.send(.advanceAfterExplain) },
                    onEarlyFinish: { store.send(.earlyFinish) }
                )
            case .result:
                QuizResultView(
                    quizSet: store.quizSet,
                    answers: store.answers,
                    onDone: { store.send(.done) }
                )
            }
        }
        .navigationBarBackButtonHidden(store.phase == .result || store.phase == .explain)
        .onChange(of: store.isDone) { _, isDone in
            if isDone { dismiss() }
        }
        .onAppear {
            store.send(.reset(quizSet))
        }
        .onChange(of: quizSet) { _, newQuizSet in
            guard store.phase == .question else { return }
            store.send(.reset(newQuizSet))
        }
    }
}

#endif
