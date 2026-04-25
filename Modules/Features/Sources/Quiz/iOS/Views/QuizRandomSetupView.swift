#if os(iOS)
import SwiftUI
import DesignSystem
import Entity

// MARK: - Random Quiz Setup

struct QuizRandomSetupView: View {
    let categories: [QuizCategoryUIModel]

    @State private var selectedCategories: Set<String> = []
    @State private var selectedTypes: Set<QuizQuestionType> = [.mcq, .ox, .fill]
    @State private var questionCount = 10
    @State private var generatedSet: QuizSet? = nil
    @State private var showFlow = false

    private let countOptions = [5, 10, 15, 20]

    var body: some View {
        ZStack {
            BrandPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // 주제 선택
                    VStack(alignment: .leading, spacing: 10) {
                        setupSectionLabel("주제 선택", subtitle: "복수 선택 가능")

                        ForEach(categories) { category in
                            categoryToggleRow(category)
                        }

                        Button {
                            if selectedCategories.count == categories.count {
                                selectedCategories.removeAll()
                            } else {
                                selectedCategories = Set(categories.map(\.id))
                            }
                        } label: {
                            Text(selectedCategories.count == categories.count ? "전체 해제" : "전체 선택")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(BrandPalette.ink3)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // 문제 유형
                    VStack(alignment: .leading, spacing: 10) {
                        setupSectionLabel("문제 유형", subtitle: "복수 선택 가능")

                        HStack(spacing: 8) {
                            typeToggle("OX", type: .ox)
                            typeToggle("객관식", type: .mcq)
                            typeToggle("빈칸 채우기", type: .fill)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // 문제 수
                    VStack(alignment: .leading, spacing: 10) {
                        setupSectionLabel("문제 수", subtitle: nil)

                        HStack(spacing: 8) {
                            ForEach(countOptions, id: \.self) { count in
                                countButton(count)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // 풀 요약
                    let pool = poolCount
                    let actual = min(questionCount, pool)
                    HStack(spacing: 10) {
                        Image(systemName: pool > 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(pool > 0 ? BrandPalette.green : BrandPalette.danger)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pool > 0
                                 ? "총 \(pool)문제 풀에서 \(actual)문제 출제"
                                 : "선택된 풀에 문제가 없습니다")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(pool > 0 ? BrandPalette.ink : BrandPalette.danger)

                            if pool > 0 && questionCount > pool {
                                Text("선택 개수(\(questionCount))가 풀 크기보다 커 전체 \(pool)문제 출제")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(BrandPalette.ink3)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(pool > 0 ? BrandPalette.greenSoft : BrandPalette.dangerSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .padding(.top, 22)

                    // 시작하기
                    Button(action: startQuiz) {
                        HStack {
                            Text("시작하기")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(canStart ? .white : BrandPalette.ink3)

                            Spacer()

                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(
                                    canStart
                                    ? Color(red: 0.231, green: 0.165, blue: 0.031)
                                    : BrandPalette.ink3
                                )
                                .frame(width: 40, height: 40)
                                .background(canStart ? BrandPalette.banana : BrandPalette.surfaceAlt)
                                .clipShape(Circle())
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(canStart ? BrandPalette.ink : BrandPalette.surfaceAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .opacity(canStart ? 1 : 0.5)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(!canStart)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
            }
        }
        .navigationTitle("랜덤 퀴즈")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showFlow) {
            if let set = generatedSet {
                QuizFlowView(quizSet: set)
            }
        }
        .onAppear {
            if selectedCategories.isEmpty {
                selectedCategories = Set(categories.map(\.id))
            }
        }
    }

    // MARK: - Computed

    private var canStart: Bool {
        !selectedCategories.isEmpty && !selectedTypes.isEmpty && poolCount > 0
    }

    private var poolCount: Int {
        categories
            .filter { selectedCategories.contains($0.id) }
            .flatMap(\.questions)
            .filter { selectedTypes.contains($0.type) }
            .count
    }

    // MARK: - Actions

    private func startQuiz() {
        let pool = categories
            .filter { selectedCategories.contains($0.id) }
            .flatMap(\.questions)
            .filter { selectedTypes.contains($0.type) }
            .shuffled()
            .prefix(questionCount)

        guard !pool.isEmpty else { return }

        generatedSet = QuizSet(
            chapter: "랜덤 퀴즈",
            chapterNum: "—",
            discipline: "Mixed",
            questions: Array(pool),
            passingScore: 80
        )
        showFlow = true
    }

    // MARK: - Sub-views

    private func categoryToggleRow(_ category: QuizCategoryUIModel) -> some View {
        let on = selectedCategories.contains(category.id)
        return Button {
            if on { selectedCategories.remove(category.id) }
            else  { selectedCategories.insert(category.id) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(on ? .white : category.iconColor)
                    .frame(width: 36, height: 36)
                    .background(on ? category.iconColor : category.iconBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 1) {
                    Text(category.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(on ? BrandPalette.ink : BrandPalette.ink2)
                    Text("\(category.questions.count)문제")
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                        .foregroundStyle(BrandPalette.ink3)
                }

                Spacer()

                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(on ? BrandPalette.green : BrandPalette.ink4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(on ? BrandPalette.greenSoft : BrandPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(on ? BrandPalette.green : BrandPalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func typeToggle(_ label: String, type: QuizQuestionType) -> some View {
        let on = selectedTypes.contains(type)
        return Button {
            if on { selectedTypes.remove(type) } else { selectedTypes.insert(type) }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(on ? .white : BrandPalette.ink2)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(on ? BrandPalette.green : BrandPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(on ? BrandPalette.green : BrandPalette.line, lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func countButton(_ count: Int) -> some View {
        let on = questionCount == count
        return Button { questionCount = count } label: {
            Text("\(count)")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(on ? .white : BrandPalette.ink2)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(on ? BrandPalette.ink : BrandPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(on ? BrandPalette.ink : BrandPalette.line, lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func setupSectionLabel(_ title: String, subtitle: String?) -> some View {
        HStack(alignment: .bottom, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(BrandPalette.ink)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(BrandPalette.ink3)
            }
        }
    }
}
#endif
