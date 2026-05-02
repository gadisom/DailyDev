#if os(iOS)
import SwiftUI
import SwiftData
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

// MARK: - Question View

struct QuizQuestionView: View {
    let question: QuizQuestion
    let quizSet: QuizSet
    let answers: [Int: String]
    let index: Int
    let total: Int
    let categoryName: String
    @Binding var selectedChoices: Set<Int>
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
        case .mcq:  return !selectedChoices.isEmpty
        case .ox:   return selectedOX != nil
        case .fill: return !fillInput.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if total > 1 {
                progressBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Type + tag chips
                    HStack(spacing: 8) {
                        DailyDevChip(typeLabel, tone: .green, size: .sm)
                        DailyDevChip(question.tag, tone: .outline, size: .sm)
                        if question.isMultiSelect {
                            DailyDevChip("복수 선택", tone: .neutral, size: .sm)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Question text
                    VStack(alignment: .leading, spacing: 10) {
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
                        if question.isMultiSelect {
                            Text("해당하는 것을 모두 선택하세요")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(BrandPalette.ink3)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                        .fill(progressColor(at: i))
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

    private func progressColor(at barIndex: Int) -> Color {
        if barIndex == index {
            return BrandPalette.banana
        }

        guard barIndex >= 0, barIndex < quizSet.questions.count else {
            return BrandPalette.surfaceAlt
        }

        let qid = quizSet.questions[barIndex].id
        switch answers[qid] {
        case "correct":
            return BrandPalette.green
        case "wrong":
            return BrandPalette.danger
        default:
            return BrandPalette.surfaceAlt
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
                correctIndices: question.correctIndices,
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
            let on = selectedChoices.contains(i)
            Button {
                if question.isMultiSelect {
                    if selectedChoices.contains(i) {
                        selectedChoices.remove(i)
                    } else {
                        selectedChoices.insert(i)
                    }
                } else {
                    selectedChoices = [i]
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        if question.isMultiSelect {
                            Image(systemName: on ? "checkmark.square.fill" : "square")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(on ? .white : BrandPalette.ink3)
                        } else {
                            Text(String(UnicodeScalar(65 + i)!))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(on ? .white : BrandPalette.ink3)
                        }
                    }
                    .frame(width: 28, height: 28)
                    .background(on ? Color.white.opacity(0.2) : BrandPalette.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: question.isMultiSelect ? 6 : 8))

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

            TextField("", text: $fillInput)
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
    let quizSet: QuizSet
    let answers: [Int: String]
    let userAnswer: String?
    let index: Int
    let total: Int
    let categoryName: String
    let allowsEarlyExit: Bool
    let onNext: () -> Void
    let onEarlyFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var savedQuestions: [SavedQuizQuestion]

    private var isCorrect: Bool { userAnswer == "correct" }
    private var isLast: Bool { index == total - 1 }
    private var isSaved: Bool { savedQuestions.contains { $0.questionID == question.id } }

    var body: some View {
        VStack(spacing: 0) {
            if total > 1 {
                // Progress
                progressBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }

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
                                let isRight = question.correctIndices.contains(i)
                                HStack(spacing: 12) {
                                    if question.isMultiSelect {
                                        Image(systemName: isRight ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(isRight ? .white : BrandPalette.ink3)
                                            .frame(width: 22, height: 22)
                                            .background(isRight ? BrandPalette.green : BrandPalette.surfaceAlt)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    } else {
                                        Text(String(UnicodeScalar(65 + i)!))
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(isRight ? .white : BrandPalette.ink3)
                                            .frame(width: 22, height: 22)
                                            .background(isRight ? BrandPalette.green : BrandPalette.surfaceAlt)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }

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
        .toolbar {
            if total == 1 {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        toggleSavedQuestion()
                    } label: {
                        Label(
                            isSaved ? "저장됨" : "저장",
                            systemImage: isSaved ? "bookmark.fill" : "bookmark"
                        )
                    }
                    .tint(isSaved ? BrandPalette.green : BrandPalette.ink3)
                }
            }
        }
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(0..<total, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor(at: i))
                        .frame(height: 6)
                }
            }
            Text("\(index + 1)/\(total)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(BrandPalette.ink2)
                .frame(minWidth: 30, alignment: .trailing)
        }
    }

    private func progressColor(at barIndex: Int) -> Color {
        if barIndex == index {
            return BrandPalette.banana
        }

        guard barIndex >= 0, barIndex < quizSet.questions.count else {
            return BrandPalette.surfaceAlt
        }

        let qid = quizSet.questions[barIndex].id
        switch answers[qid] {
        case "correct":
            return BrandPalette.green
        case "wrong":
            return BrandPalette.danger
        default:
            return BrandPalette.surfaceAlt
        }
    }

    private func toggleSavedQuestion() {
        if let existing = savedQuestions.first(where: { $0.questionID == question.id }) {
            modelContext.delete(existing)
            return
        }

        let typeStr: String = {
            switch question.type {
            case .mcq: return "mcq"
            case .ox: return "ox"
            case .fill: return "fill"
            }
        }()

        modelContext.insert(SavedQuizQuestion(
            questionID: question.id,
            question: question.question,
            questionType: typeStr,
            choices: question.choices,
            correctIndices: question.correctIndices,
            oxAnswer: question.oxAnswer,
            fillAnswer: question.fillAnswer,
            explanation: question.explanation,
            concept: question.concept,
            tag: question.tag,
            categoryName: categoryName
        ))
    }
}

// MARK: - Result View

struct QuizResultView: View {
    let quizSet: QuizSet
    let answers: [Int: String]
    let onDone: () -> Void

    @State private var selectedWrongIDs: Set<Int> = []
    @State private var selectedRemoveIDs: Set<Int> = []
    @Environment(\.modelContext) private var modelContext
    @Query private var savedQuestions: [SavedQuizQuestion]

    private var answeredQuestions: [QuizQuestion] { quizSet.questions.filter { answers[$0.id] != nil } }
    private var wrongQuestions: [QuizQuestion] { answeredQuestions.filter { answers[$0.id] == "wrong" } }
    private var correctQuestions: [QuizQuestion] { answeredQuestions.filter { answers[$0.id] == "correct" } }
    private var correctCount: Int { answers.values.filter { $0 == "correct" }.count }
    private var total: Int { answeredQuestions.count }
    private var score: Int { total == 0 ? 0 : Int(round(Double(correctCount) / Double(total) * 100)) }
    private var isSavedContext: Bool { quizSet.discipline == "Saved" }

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

                    Text("\(correctCount) / \(total) 정답")
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

                // 오답 저장
                if !isSavedContext {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("오답 저장")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.2)
                                .textCase(.uppercase)
                                .foregroundStyle(BrandPalette.ink3)
                            Spacer()
                            Text("선택된 문제: \(selectedWrongIDs.count)")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(BrandPalette.ink4)
                        }

                        if wrongQuestions.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.seal")
                                    .font(.system(size: 14, weight: .bold))
                                Text("오답이 없습니다. 저장할 문제가 없어요.")
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                            }
                            .foregroundStyle(BrandPalette.ink4)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(BrandPalette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(BrandPalette.line, lineWidth: 1))
                        } else {
                            Button {
                                saveSelectedWrong()
                            } label: {
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
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(BrandPalette.green)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(selectedWrongIDs.isEmpty)
                            .opacity(selectedWrongIDs.isEmpty ? 0.5 : 1)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                // 맞은 문제 제거 (Saved 컨텍스트 전용)
                if isSavedContext {
                    removeCorrectSection
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }

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
                        let wrongSelected = !ok && selectedWrongIDs.contains(q.id)
                        let removeSelected = ok && isSavedContext && selectedRemoveIDs.contains(q.id)
                        Button {
                            if ok && isSavedContext {
                                if selectedRemoveIDs.contains(q.id) {
                                    selectedRemoveIDs.remove(q.id)
                                } else {
                                    selectedRemoveIDs.insert(q.id)
                                }
                            } else if !ok {
                                if selectedWrongIDs.contains(q.id) {
                                    selectedWrongIDs.remove(q.id)
                                } else {
                                    selectedWrongIDs.insert(q.id)
                                }
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

                                if ok && isSavedContext {
                                    Image(systemName: removeSelected ? "bookmark.slash.fill" : "bookmark.slash")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(removeSelected ? BrandPalette.ink : BrandPalette.ink4)
                                } else {
                                    Image(systemName: ok ? "chevron.right" : (wrongSelected ? "checkmark.circle.fill" : "circle"))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(ok ? BrandPalette.ink4 : BrandPalette.green)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(BrandPalette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    removeSelected ? BrandPalette.ink
                                    : wrongSelected ? BrandPalette.green
                                    : BrandPalette.line,
                                    lineWidth: (removeSelected || wrongSelected) ? 1.5 : 1
                                ))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)

                // Actions
                VStack(spacing: 10) {
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
            if isSavedContext {
                selectedRemoveIDs = Set(
                    correctQuestions
                        .filter { q in savedQuestions.contains(where: { $0.questionID == q.id }) }
                        .map(\.id)
                )
            }
        }
    }

    @ViewBuilder
    private var removeCorrectSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("맞은 문제 제거")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(BrandPalette.ink3)
                Spacer()
                Text("\(selectedRemoveIDs.count)개 선택됨")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(BrandPalette.ink4)
            }

            if correctQuestions.isEmpty {
                HStack {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14, weight: .bold))
                    Text("맞은 문제가 없어요.")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                }
                .foregroundStyle(BrandPalette.ink4)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BrandPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(BrandPalette.line, lineWidth: 1))
            } else {
                Button {
                    removeSelectedCorrect()
                } label: {
                    HStack {
                        Image(systemName: "bookmark.slash.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("저장에서 제거 (\(selectedRemoveIDs.count))")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 52)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BrandPalette.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(selectedRemoveIDs.isEmpty)
                .opacity(selectedRemoveIDs.isEmpty ? 0.5 : 1)
            }
        }
    }

    private func removeSelectedCorrect() {
        for q in correctQuestions where selectedRemoveIDs.contains(q.id) {
            if let existing = savedQuestions.first(where: { $0.questionID == q.id }) {
                modelContext.delete(existing)
            }
        }
        selectedRemoveIDs = []
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
                correctIndices: q.correctIndices,
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
