#if os(iOS)
import SwiftUI
import SwiftData
import DesignSystem
import Entity

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
                quizFlowCTAButton(total == 1 ? "완료" : (isLast ? "결과 보기" : "다음 문제"), enabled: true,
                          style: isCorrect ? .green : .dark, action: onNext)
                if allowsEarlyExit && total > 1 {
                    quizFlowCTAButton("완료", enabled: true, style: .outline, action: onEarlyFinish)
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


#endif
