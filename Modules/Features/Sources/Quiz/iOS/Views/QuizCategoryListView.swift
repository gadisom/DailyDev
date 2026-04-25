#if os(iOS)
import SwiftUI
import DesignSystem
import Entity

// MARK: - Category Question List

struct QuizCategoryListView: View {
    let category: QuizCategoryUIModel

    var body: some View {
        ZStack {
            BrandPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Category header
                    HStack(spacing: 14) {
                        Image(systemName: category.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(category.iconColor)
                            .frame(width: 52, height: 52)
                            .background(category.iconBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(category.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(BrandPalette.ink)
                        }

                        Spacer()

                        VStack(spacing: 2) {
                            Text("\(category.questions.count)")
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundStyle(BrandPalette.green)
                            Text("문제")
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(BrandPalette.ink3)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Sections by question type
                    ForEach(category.questionsByType, id: \.tag) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            typeSection(ko: section.label, en: section.tag, count: section.items.count)

                            ForEach(section.items) { question in
                                NavigationLink(destination: QuizFlowView(quizSet: singleQuizSet(question))) {
                                    questionRow(question)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 22)
                    }

                    // Start CTA
                    NavigationLink(destination: QuizFlowView(quizSet: category.toQuizSet())) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("전체 \(category.questions.count)문제")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text("퀴즈 시작하기")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(red: 0.231, green: 0.165, blue: 0.031))
                                .frame(width: 40, height: 40)
                                .background(BrandPalette.banana)
                                .clipShape(Circle())
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(BrandPalette.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                    .padding(.bottom, 48)
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func singleQuizSet(_ question: QuizQuestion) -> QuizSet {
        let start = category.questions.firstIndex(where: { $0.id == question.id }) ?? 0
        let qs = Array(category.questions[start...])
        return QuizSet(chapter: category.name, chapterNum: "—", discipline: category.name,
                       questions: qs, passingScore: 80, allowsEarlyExit: true)
    }

    private func typeSection(ko: String, en: String, count: Int) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 1) {
                Text(en.uppercased())
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(BrandPalette.ink4)
                Text(ko)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(BrandPalette.ink)
            }
            Spacer()
            Text("\(count)문제")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(BrandPalette.ink3)
        }
        .padding(.bottom, 2)
    }

    private func questionRow(_ question: QuizQuestion) -> some View {
        HStack(spacing: 12) {
            typeTag(question.type)

            VStack(alignment: .leading, spacing: 4) {
                Text(question.question)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(BrandPalette.ink)
                    .lineLimit(2)
                    .lineSpacing(2)

                DailyDevChip(question.tag, tone: .outline, size: .sm)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(BrandPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrandPalette.line, lineWidth: 1))
    }

    private func typeTag(_ type: QuizQuestionType) -> some View {
        let label: String
        let color: Color
        switch type {
        case .mcq:  label = "MCQ"; color = Color(red: 0.17, green: 0.39, blue: 0.92)
        case .ox:   label = "OX";  color = BrandPalette.green
        case .fill: label = "빈칸"; color = Color(red: 0.88, green: 0.52, blue: 0.0)
        }
        return Text(label)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .frame(width: 34, height: 34)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
#endif
