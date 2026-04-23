#if os(iOS)
import ComposableArchitecture
import SwiftUI
import DesignSystem

// MARK: - Entry point (public)

public struct QuizScene: View {
    @State private var store: StoreOf<QuizFeature>

    public init(store: StoreOf<QuizFeature> = Store(initialState: QuizFeature.State()) { QuizFeature() }) {
        _store = State(wrappedValue: store)
    }

    public var body: some View {
        NavigationStack {
            QuizHubView(store: store)
        }
    }
}

// MARK: - Hub

private struct QuizHubView: View {
    @Bindable private var store: StoreOf<QuizFeature>

    init(store: StoreOf<QuizFeature>) {
        _store = Bindable(wrappedValue: store)
    }

    var body: some View {
        ZStack {
            BrandPalette.background.ignoresSafeArea()

            switch store.phase {
            case .loading:
                loadingView

            case let .error(message):
                errorView(message)

            case .content, .idle:
                hubContent
            }
        }
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .task { store.send(.task) }
    }

    private var hubContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                VStack(alignment: .leading, spacing: 0) {
                    Text("Quiz Hub")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(BrandPalette.green)
                        .tracking(1.4)
                        .textCase(.uppercase)

                    Text("문제 풀기")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(BrandPalette.ink)
                        .padding(.top, 10)

                    Rectangle()
                        .fill(BrandPalette.green)
                        .frame(width: 40, height: 3)
                        .clipShape(Capsule())
                        .padding(.top, 14)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                NavigationLink(destination: QuizRandomSetupView(categories: store.categories)) {
                    randomQuizCard
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 24)
                .padding(.top, 22)

                VStack(alignment: .leading, spacing: 8) {
                    hubSectionLabel("분야별 문제 모음")

                    ForEach(store.categories) { category in
                        NavigationLink(destination: QuizCategoryListView(category: category)) {
                            categoryRow(category)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 48)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .scaleEffect(1.2)
            Text("문제 불러오는 중...")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(BrandPalette.ink3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(BrandPalette.danger)

            Text("불러오기 실패")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(BrandPalette.ink)

            Text(message)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(BrandPalette.ink3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("다시 시도") {
                store.send(.refreshTapped)
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(BrandPalette.ink)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func categoryRow(_ category: QuizCategory) -> some View {
        HStack(spacing: 14) {
            Image(systemName: category.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(category.iconColor)
                .frame(width: 42, height: 42)
                .background(category.iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(BrandPalette.ink)
                Text(category.englishName)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(BrandPalette.ink3)
            }

            Spacer()

            Text("\(category.questions.count)문제")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(BrandPalette.ink3)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BrandPalette.ink4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(BrandPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(BrandPalette.line, lineWidth: 1))
    }

    private func hubSectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(BrandPalette.ink3)
            .padding(.bottom, 2)
    }

    private var randomQuizCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "shuffle")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text("RANDOM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.6))
                Text("랜덤 퀴즈")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Text("주제 · 유형 · 개수 직접 설정")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(BrandPalette.green)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct QuizIntroView: View {
    let quizSet: QuizSet
    @State private var showFlow = false

    private var mcqCount: Int { quizSet.questions.filter { $0.type == .mcq }.count }
    private var oxCount: Int  { quizSet.questions.filter { $0.type == .ox  }.count }
    private var fillCount: Int { quizSet.questions.filter { $0.type == .fill }.count }

    var body: some View {
        ZStack {
            BrandPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Chapter \(quizSet.chapterNum) · \(quizSet.discipline)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(BrandPalette.green)
                            .tracking(1.4)
                            .textCase(.uppercase)

                        Text(quizSet.chapter)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(BrandPalette.ink)
                            .padding(.top, 10)

                        Rectangle()
                            .fill(BrandPalette.green)
                            .frame(width: 40, height: 3)
                            .clipShape(Capsule())
                            .padding(.top, 14)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    HStack(spacing: 0) {
                        ForEach([
                            (value: "\(quizSet.questions.count)", label: "문제"),
                            (value: "~3",                         label: "분 소요"),
                            (value: "\(quizSet.passingScore)%",   label: "합격선"),
                        ], id: \.label) { item in
                            VStack(spacing: 4) {
                                Text(item.value)
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BrandPalette.ink)
                                Text(item.label)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundStyle(BrandPalette.ink3)
                            }
                            .frame(maxWidth: .infinity)

                            if item.label != "합격선" {
                                Divider().frame(height: 28)
                            }
                        }
                    }
                    .padding(.vertical, 14)
                    .background(BrandPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(BrandPalette.line, lineWidth: 1))
                    .padding(.horizontal, 24)
                    .padding(.top, 22)

                    VStack(alignment: .leading, spacing: 8) {
                        introSectionLabel("Question Types")

                        ForEach([
                            (ko: "객관식",     en: "Multiple Choice",    n: mcqCount),
                            (ko: "OX",        en: "True / False",       n: oxCount),
                            (ko: "빈칸 채우기", en: "Fill in the Blank", n: fillCount),
                        ].filter { $0.n > 0 }, id: \.en) { item in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.ko)
                                        .font(.system(size: 13.5, weight: .semibold))
                                        .foregroundStyle(BrandPalette.ink)
                                    Text(item.en)
                                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                        .foregroundStyle(BrandPalette.ink3)
                                }
                                Spacer()
                                Text("× \(item.n)")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(BrandPalette.ink3)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(BrandPalette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrandPalette.line, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 22)

                    NavigationLink(destination: QuizFlowView(quizSet: quizSet)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ready?")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .textCase(.uppercase)
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
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func introSectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(BrandPalette.ink3)
            .padding(.bottom, 2)
    }
}

// MARK: - Chip helper (local)

private func chipView(_ text: String, tone: ChipTone, size: DailyDevChip.ChipSize = .sm) -> some View {
    DailyDevChip(text, tone: tone, size: size)
}
#endif
