#if os(iOS)
import SwiftUI
import SwiftData
import DesignSystem
import Entity

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
                    quizFlowCTAButton("완료", enabled: true, style: .outline, action: onDone)
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

#endif
