#if os(iOS)
import SwiftUI
import SwiftData
import DesignSystem
import Entity

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
                    .padding(.bottom, 100)
                }
            }

            // Bottom CTA
            quizFlowCTAButton("정답 확인", enabled: canConfirm, style: .dark, action: onConfirm)
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


#endif
