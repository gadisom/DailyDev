#if os(iOS)
import SwiftUI
import SwiftData
import ComposableArchitecture
import DesignSystem
import Entity

// MARK: - Flow coordinator

struct QuizFlowView: View {
    @State private var store: StoreOf<QuizFlowFeature>
    @Environment(\.dismiss) private var dismiss

    init(quizSet: QuizSet) {
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
                    index: store.currentIndex,
                    total: store.total,
                    categoryName: store.quizSet.chapter,
                    selectedChoice: $store.selectedChoice,
                    selectedOX: $store.selectedOX,
                    fillInput: $store.fillInput,
                    onConfirm: { store.send(.confirmAnswer) }
                )
            case .explain:
                QuizExplainView(
                    question: store.current,
                    userAnswer: store.answers[store.current.id],
                    index: store.currentIndex,
                    total: store.total,
                    allowsEarlyExit: store.quizSet.allowsEarlyExit,
                    onNext: { store.send(.advanceAfterExplain) },
                    onEarlyFinish: { store.send(.earlyFinish) }
                )
            case .result:
                QuizResultView(
                    quizSet: store.quizSet,
                    answers: store.answers,
                    onRetryWrong: { store.send(.retryWrong) },
                    onDone: { store.send(.done) }
                )
                .navigationDestination(isPresented: $store.showWrongNotes) {
                    WrongNotesView()
                }
            }
        }
        .navigationBarBackButtonHidden(store.phase == .result || store.phase == .explain)
        .onChange(of: store.isDone) { _, isDone in
            if isDone { dismiss() }
        }
    }
}

// MARK: - Question View

struct QuizQuestionView: View {
    let question: QuizQuestion
    let index: Int
    let total: Int
    let categoryName: String
    @Binding var selectedChoice: Int?
    @Binding var selectedOX: String?
    @Binding var fillInput: String

    let onConfirm: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var savedQuestions: [SavedQuizQuestion]

    private var isBookmarked: Bool {
        savedQuestions.contains { $0.questionID == question.id }
    }

    private var canConfirm: Bool {
        switch question.type {
        case .mcq:  return selectedChoice != nil
        case .ox:   return selectedOX != nil
        case .fill: return !fillInput.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            progressBar
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Type + tag chips
                    HStack(spacing: 8) {
                        DailyDevChip(typeLabel, tone: .green, size: .sm)
                        DailyDevChip(question.tag, tone: .outline, size: .sm)
                    }
                    .padding(.horizontal, 24)

                    // Question number + text
                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(format: "Question %02d", question.id))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(BrandPalette.ink3)

                        Text(question.question)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(BrandPalette.ink)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                    // Choices
                    VStack(spacing: 10) {
                        switch question.type {
                        case .mcq:  mcqChoices
                        case .ox:   oxChoices
                        case .fill: fillChoice
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
            }

            // Bottom CTA
            ctaButton("정답 확인", enabled: canConfirm, style: .dark, action: onConfirm)
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
        }
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(0..<total, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < index ? BrandPalette.green
                              : i == index ? BrandPalette.banana
                              : BrandPalette.surfaceAlt)
                        .frame(height: 6)
                }
            }
            Text("\(index + 1)/\(total)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(BrandPalette.ink2)
                .frame(minWidth: 30, alignment: .trailing)

            Button { toggleBookmark() } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isBookmarked ? BrandPalette.green : BrandPalette.ink3)
            }
            .buttonStyle(.plain)
        }
    }

    private func toggleBookmark() {
        if let existing = savedQuestions.first(where: { $0.questionID == question.id }) {
            modelContext.delete(existing)
        } else {
            let typeStr: String = {
                switch question.type {
                case .mcq: return "mcq"
                case .ox:  return "ox"
                case .fill: return "fill"
                }
            }()
            modelContext.insert(SavedQuizQuestion(
                questionID: question.id,
                question: question.question,
                questionType: typeStr,
                choices: question.choices,
                correctIndex: question.correctIndex,
                oxAnswer: question.oxAnswer,
                fillAnswer: question.fillAnswer,
                explanation: question.explanation,
                concept: question.concept,
                tag: question.tag,
                categoryName: categoryName
            ))
        }
    }

    private var typeLabel: String {
        switch question.type {
        case .mcq:  return "객관식"
        case .ox:   return "OX"
        case .fill: return "빈칸"
        }
    }

    @ViewBuilder
    private var mcqChoices: some View {
        ForEach(Array(question.choices.enumerated()), id: \.offset) { i, choice in
            let on = selectedChoice == i
            Button { selectedChoice = i } label: {
                HStack(spacing: 14) {
                    Text(String(UnicodeScalar(65 + i)!))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(on ? .white : BrandPalette.ink3)
                        .frame(width: 28, height: 28)
                        .background(on ? Color.white.opacity(0.2) : BrandPalette.surfaceAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text(choice)
                        .font(.system(size: 15, weight: on ? .semibold : .regular, design: .monospaced))
                        .foregroundStyle(on ? .white : BrandPalette.ink)
                        .multilineTextAlignment(.leading)

                    Spacer()
                }
                .padding(16)
                .background(on ? BrandPalette.green : BrandPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(on ? BrandPalette.green : BrandPalette.line, lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    @ViewBuilder
    private var oxChoices: some View {
        HStack(spacing: 12) {
            ForEach(["O", "X"], id: \.self) { val in
                let on = selectedOX == val
                let color: Color = val == "O" ? BrandPalette.green : BrandPalette.danger
                Button { selectedOX = val } label: {
                    Text(val)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(on ? .white : color)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(on ? color : color.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(on ? color : color.opacity(0.25), lineWidth: 1.5))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var fillChoice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("답을 입력하세요")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(BrandPalette.ink3)

            TextField("예: O(n)", text: $fillInput)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(BrandPalette.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(BrandPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(fillInput.isEmpty ? BrandPalette.line : BrandPalette.green, lineWidth: 1.5))
        }
    }
}

// MARK: - Explain View

struct QuizExplainView: View {
    let question: QuizQuestion
    let userAnswer: String?
    let index: Int
    let total: Int
    let allowsEarlyExit: Bool
    let onNext: () -> Void
    let onEarlyFinish: () -> Void

    private var isCorrect: Bool { userAnswer == "correct" }
    private var isLast: Bool { index == total - 1 }

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            progressBar
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Result banner
                    HStack(spacing: 12) {
                        Image(systemName: isCorrect ? "checkmark" : "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(isCorrect ? BrandPalette.green : BrandPalette.danger)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 1) {
                            Text(isCorrect ? "정답" : "오답")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(isCorrect ? BrandPalette.greenInk : BrandPalette.danger)
                                .tracking(1)
                                .textCase(.uppercase)
                                .opacity(0.7)
                            Text(isCorrect ? "정확해요!" : "아쉬워요.")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(isCorrect ? BrandPalette.greenInk : BrandPalette.danger)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(isCorrect ? BrandPalette.greenSoft : BrandPalette.dangerSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)

                    // Question
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(format: "Question %02d", question.id))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(BrandPalette.ink3)

                        Text(question.question)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(BrandPalette.ink)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Choices (MCQ only)
                    if question.type == .mcq {
                        VStack(spacing: 8) {
                            ForEach(Array(question.choices.enumerated()), id: \.offset) { i, choice in
                                let isRight = i == question.correctIndex
                                HStack(spacing: 12) {
                                    Text(String(UnicodeScalar(65 + i)!))
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(isRight ? .white : BrandPalette.ink3)
                                        .frame(width: 22, height: 22)
                                        .background(isRight ? BrandPalette.green : BrandPalette.surfaceAlt)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))

                                    Text(choice)
                                        .font(.system(size: 13.5, weight: .medium, design: .monospaced))
                                        .foregroundStyle(isRight ? BrandPalette.greenInk : BrandPalette.ink2)

                                    Spacer()

                                    if isRight {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(BrandPalette.green)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(isRight ? BrandPalette.greenSoft : BrandPalette.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(isRight ? BrandPalette.green : BrandPalette.line, lineWidth: 1))
                                .opacity(isRight ? 1 : 0.5)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                    }

                    // OX answer
                    if question.type == .ox {
                        Text("정답: \(question.oxAnswer)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(question.oxAnswer == "O" ? BrandPalette.green : BrandPalette.danger)
                            .padding(.horizontal, 24)
                            .padding(.top, 14)
                    }

                    // Fill answer
                    if question.type == .fill {
                        HStack(spacing: 8) {
                            Text("정답")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(BrandPalette.green)
                                .tracking(0.8)
                                .textCase(.uppercase)
                            Text(question.fillAnswer)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(BrandPalette.ink)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                    }

                    // Explanation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("해설")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.2)
                                .textCase(.uppercase)
                                .foregroundStyle(BrandPalette.ink3)
                            Spacer()
                            DailyDevChip(question.tag, tone: .outline, size: .sm)
                        }

                        Text(question.explanation)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(BrandPalette.ink2)
                            .lineSpacing(5)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(BrandPalette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(BrandPalette.line, lineWidth: 1))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                    Spacer()
                        .frame(height: 120)
                }
            }

            VStack(spacing: 10) {
                ctaButton(total == 1 ? "완료" : (isLast ? "결과 보기" : "다음 문제"), enabled: true,
                          style: isCorrect ? .green : .dark, action: onNext)
                if allowsEarlyExit && total > 1 {
                    ctaButton("완료", enabled: true, style: .outline, action: onEarlyFinish)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(0..<total, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= index ? BrandPalette.green : BrandPalette.surfaceAlt)
                        .frame(height: 6)
                }
            }
            Text("\(index + 1)/\(total)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(BrandPalette.ink2)
                .frame(minWidth: 30, alignment: .trailing)
        }
    }
}

// MARK: - Result View

struct QuizResultView: View {
    let quizSet: QuizSet
    let answers: [Int: String]
    let onRetryWrong: () -> Void
    let onDone: () -> Void

    @State private var selectedWrongIDs: Set<Int> = []
    @Environment(\.modelContext) private var modelContext
    @Query private var savedQuestions: [SavedQuizQuestion]

    private var answeredQuestions: [QuizQuestion] { quizSet.questions.filter { answers[$0.id] != nil } }
    private var correctCount: Int { answers.values.filter { $0 == "correct" }.count }
    private var total: Int { answeredQuestions.count }
    private var score: Int { total == 0 ? 0 : Int(round(Double(correctCount) / Double(total) * 100)) }
    private var passed: Bool { score >= quizSet.passingScore }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // Score hero
                VStack(alignment: .leading, spacing: 0) {
                    Text(quizSet.chapter)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(1.2)
                        .textCase(.uppercase)

                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("\(score)")
                            .font(.system(size: 64, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        Text("/100")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.top, 16)

                    Text("\(correctCount) / \(total) 정답 · \(passed ? "합격" : "불합격")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.top, 4)

                    // Segment dots
                    HStack(spacing: 4) {
                        ForEach(answeredQuestions) { q in
                            let ok = answers[q.id] == "correct"
                            RoundedRectangle(cornerRadius: 2)
                                .fill(ok ? BrandPalette.banana : Color.white.opacity(0.25))
                                .frame(height: 4)
                        }
                    }
                    .padding(.top, 18)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BrandPalette.green)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 140, height: 140)
                        .offset(x: 60, y: -50)
                        .clipped(),
                    alignment: .topTrailing
                )
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Review
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Review")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(BrandPalette.ink3)
                        Spacer()
                        DailyDevChip("\(total - correctCount)개 오답", tone: .neutral, size: .sm)
                    }
                    .padding(.bottom, 2)

                    ForEach(answeredQuestions) { q in
                        let ok = answers[q.id] == "correct"
                        let selected = !ok && selectedWrongIDs.contains(q.id)
                        Button {
                            guard !ok else { return }
                            if selectedWrongIDs.contains(q.id) {
                                selectedWrongIDs.remove(q.id)
                            } else {
                                selectedWrongIDs.insert(q.id)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: ok ? "checkmark" : "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(ok ? BrandPalette.green : BrandPalette.danger)
                                    .frame(width: 28, height: 28)
                                    .background(ok ? BrandPalette.greenSoft : BrandPalette.dangerSoft)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(format: "Q%02d · %@", q.id, typeLabel(q.type)))
                                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                        .tracking(0.6)
                                        .textCase(.uppercase)
                                        .foregroundStyle(BrandPalette.ink3)
                                    Text(q.question.replacingOccurrences(of: "\n", with: " "))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(BrandPalette.ink)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: ok ? "chevron.right" : (selected ? "checkmark.circle.fill" : "circle"))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(ok ? BrandPalette.ink4 : BrandPalette.green)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(BrandPalette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(selected ? BrandPalette.green : BrandPalette.line,
                                        lineWidth: selected ? 1.5 : 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)

                // Actions
                VStack(spacing: 10) {
                    if !selectedWrongIDs.isEmpty {
                        Button { saveSelectedWrong() } label: {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("오답 저장 (\(selectedWrongIDs.count))")
                                    .font(.system(size: 15, weight: .bold))
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 52)
                            .background(BrandPalette.green)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    ctaButton("틀린 문제만 다시 풀기", enabled: true, style: .dark, action: onRetryWrong)
                    ctaButton("완료", enabled: true, style: .outline, action: onDone)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Result")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            selectedWrongIDs = Set(quizSet.questions.filter { answers[$0.id] == "wrong" }.map(\.id))
        }
    }

    private func saveSelectedWrong() {
        for q in answeredQuestions where selectedWrongIDs.contains(q.id) {
            guard !savedQuestions.contains(where: { $0.questionID == q.id }) else { continue }
            let typeStr: String = {
                switch q.type {
                case .mcq: return "mcq"
                case .ox:  return "ox"
                case .fill: return "fill"
                }
            }()
            modelContext.insert(SavedQuizQuestion(
                questionID: q.id,
                question: q.question,
                questionType: typeStr,
                choices: q.choices,
                correctIndex: q.correctIndex,
                oxAnswer: q.oxAnswer,
                fillAnswer: q.fillAnswer,
                explanation: q.explanation,
                concept: q.concept,
                tag: q.tag,
                categoryName: quizSet.chapter
            ))
        }
        selectedWrongIDs = []
    }

    private func typeLabel(_ type: QuizQuestionType) -> String {
        switch type {
        case .mcq:  return "객관식"
        case .ox:   return "OX"
        case .fill: return "빈칸"
        }
    }
}

// MARK: - Wrong Notes View

struct WrongNotesView: View {
    @State private var selectedFilter = "전체"
    private let filters = ["전체", "자료구조", "알고리즘", "자주 틀림"]

    var body: some View {
        ZStack {
            BrandPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Summary card
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("누적 오답")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(1.2)
                                .textCase(.uppercase)
                                .foregroundStyle(BrandPalette.ink3)

                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("\(dummyWrongNotes.count)")
                                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BrandPalette.ink)
                                Text("문제")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(BrandPalette.ink4)
                            }
                        }

                        Spacer()

                        Button(action: {}) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 11))
                                Text("한번에 복습")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(BrandPalette.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(BrandPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(BrandPalette.line, lineWidth: 1))
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(filters, id: \.self) { f in
                                Button { selectedFilter = f } label: {
                                    DailyDevChip(
                                        f == "전체" ? "전체 · \(dummyWrongNotes.count)" : f,
                                        tone: selectedFilter == f ? .green : .neutral,
                                        size: .sm
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 14)

                    // List
                    VStack(spacing: 10) {
                        ForEach(dummyWrongNotes) { item in
                            wrongNoteCard(item)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    .padding(.bottom, 48)
                }
            }
        }
        .navigationTitle("오답노트")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func wrongNoteCard(_ item: WrongNoteItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("CH \(item.chapterNum)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(BrandPalette.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(BrandPalette.greenSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Text(item.chapter)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(BrandPalette.ink2)

                Spacer()

                if item.wrongCount > 1 {
                    DailyDevChip("× \(item.wrongCount)", tone: .banana, size: .sm)
                }
            }
            .padding(.bottom, 8)

            Text(item.question)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BrandPalette.ink)
                .lineSpacing(3)

            HStack(spacing: 8) {
                DailyDevChip(item.type, tone: .outline, size: .sm)
                DailyDevChip(item.tag, tone: .outline, size: .sm)
                Spacer()
                Text(item.relativeDate)
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(BrandPalette.ink3)
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(BrandPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(BrandPalette.line, lineWidth: 1))
    }
}

// MARK: - Shared helpers

private enum CTAStyle { case dark, green, outline }

private func ctaButton(
    _ label: String,
    enabled: Bool,
    style: CTAStyle,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(style == .outline ? BrandPalette.ink : .white)
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(style == .outline ? BrandPalette.ink2 : .white)
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .background(
            style == .dark ? BrandPalette.ink
            : style == .green ? BrandPalette.green
            : BrandPalette.surface
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            style == .outline
            ? RoundedRectangle(cornerRadius: 14).stroke(BrandPalette.line, lineWidth: 1)
            : nil
        )
        .opacity(enabled ? 1 : 0.4)
    }
    .buttonStyle(ScaleButtonStyle())
    .disabled(!enabled)
}
#endif
