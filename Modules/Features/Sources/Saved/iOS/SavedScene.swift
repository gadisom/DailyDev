#if os(iOS)
import SwiftUI
import SwiftData
import DesignSystem
import ComposableArchitecture
import Entity

// MARK: - Entry

public struct SavedScene: View {
    private let store: StoreOf<SavedFeature>

    public init(store: StoreOf<SavedFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            SavedView(store: store)
        }
    }
}

// MARK: - Main view

private struct SavedView: View {
    @Bindable private var store: StoreOf<SavedFeature>
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \SavedConcept.savedAt, order: .reverse) private var concepts: [SavedConcept]
    @Query(sort: \SavedQuizQuestion.savedAt, order: .reverse) private var questions: [SavedQuizQuestion]
    @Query(sort: \SavedPost.savedAt, order: .reverse) private var posts: [SavedPost]
    @State private var webDestination: WebDestination?

    init(store: StoreOf<SavedFeature>) {
        _store = Bindable(wrappedValue: store)
    }

    var body: some View {
        ZStack {
            BrandPalette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                selectorBar
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)

                Divider().opacity(0.5)

                switch store.selectedTab {
                case .concepts: conceptsList
                case .quiz: quizList
                case .posts: postList
                }
            }
        }
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $store.isFullQuizFlowPresented) {
            QuizFlowView(quizSet: savedQuizSet)
        }
        .onChange(of: store.isFullQuizFlowPresented) { _, isPresented in
            if !isPresented {
                store.send(.fullQuizDismissed)
            }
        }
        .navigationDestination(item: $store.selectedQuestionID) { questionID in
            if let item = questions.first(where: { $0.questionID == questionID }) {
                QuizFlowView(quizSet: singleQuizSet(item))
            } else {
                EmptyView()
            }
        }
        .onChange(of: store.selectedQuestionID) { _, questionID in
            if questionID == nil {
                store.send(.questionDismissed)
            }
        }
        .sheet(item: $webDestination) { destination in
            InAppWebView(url: destination.url)
                .ignoresSafeArea()
        }
    }

    private var savedQuizSet: QuizSet {
        let qs = questions.compactMap { toQuizQuestion($0) }.shuffled()
        return QuizSet(
            chapter: "저장된 문제",
            chapterNum: "—",
            discipline: "Saved",
            questions: qs,
            passingScore: 80
        )
    }

    private func singleQuizSet(_ item: SavedQuizQuestion) -> QuizSet {
        let qs = toQuizQuestion(item).map { [$0] } ?? []
        return QuizSet(
            chapter: item.categoryName,
            chapterNum: "—",
            discipline: "Saved",
            questions: qs,
            passingScore: 80,
            allowsEarlyExit: true
        )
    }

    private func toQuizQuestion(_ saved: SavedQuizQuestion) -> QuizQuestion? {
        let type: QuizQuestionType = switch saved.questionType {
        case "ox":
            .ox
        case "fill":
            .fill
        default:
            .mcq
        }
        return QuizQuestion(
            id: saved.questionID,
            type: type,
            question: saved.question,
            choices: saved.choices,
            correctIndices: saved.resolvedCorrectIndices,
            oxAnswer: saved.oxAnswer,
            fillAnswer: saved.fillAnswer,
            explanation: saved.explanation,
            concept: saved.concept,
            tag: saved.tag
        )
    }

    // MARK: - Selector

    private var selectorBar: some View {
        HStack(spacing: 8) {
            ForEach(SavedFeature.State.Tab.allCases, id: \.self) { tab in
                Button {
                    store.send(.tabTapped(tab))
                } label: {
                    let on = store.selectedTab == tab
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: on ? .bold : .semibold))
                    }
                    .foregroundStyle(on ? .white : BrandPalette.ink2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
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
        }
    }

    // MARK: - Concepts

    private var conceptsList: some View {
        Group {
            if concepts.isEmpty {
                emptyState(
                    icon: "book.closed",
                    title: "저장된 개념이 없어요",
                    subtitle: "홈에서 개념을 북마크해보세요"
                )
            } else {
                List {
                ForEach(concepts) { item in
                        Button {
                            store.send(.delegate(.selectConcept(categoryID: item.categoryID, conceptID: item.conceptID)))
                        } label: {
                            conceptRow(item)
                        }
                        .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 4, trailing: 24))
                            .swipeActions(edge: .trailing) { deleteButton(item) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func conceptRow(_ item: SavedConcept) -> some View {
        let style = CurriculumCard.styleFor(id: item.categoryID, title: item.categoryTitle)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: style?.icon ?? "book.closed")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(style?.iconColor ?? BrandPalette.green)
                    .frame(width: 32, height: 32)
                    .background(style?.iconBackground ?? BrandPalette.greenSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 1) {
                    Text(item.categoryTitle.isEmpty ? "개념" : item.categoryTitle)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(BrandPalette.ink3)
                    Text(item.title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(BrandPalette.ink)
                }

                Spacer()

                Text(relativeDate(item.savedAt))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(BrandPalette.ink4)
            }

            if !item.summary.isEmpty {
                Text(item.summary)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundStyle(BrandPalette.ink3)
                    .lineLimit(2)
                    .lineSpacing(2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(BrandPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(BrandPalette.line, lineWidth: 1))
    }

    // MARK: - Quiz

    private var quizList: some View {
        Group {
            if questions.isEmpty {
                emptyState(
                    icon: "questionmark.circle",
                    title: "저장된 문제가 없어요",
                    subtitle: "퀴즈에서 문제를 북마크해보세요"
                )
            } else {
                VStack(spacing: 0) {
                    Button {
                        store.send(.fullQuizTapped)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13, weight: .bold))
                            Text("전체 다시 풀기")
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            Text("\(questions.count)문제")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.75))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 46)
                        .background(BrandPalette.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                    List {
                        ForEach(questions) { item in
                            Button {
                                store.send(.questionTapped(item.questionID))
                            } label: {
                                quizRow(item)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 4, trailing: 24))
                            .swipeActions(edge: .trailing) { deleteButton(item) }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }

    private func quizRow(_ item: SavedQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                typeTag(item.questionType)

                if !item.categoryName.isEmpty {
                    Text(item.categoryName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(BrandPalette.ink3)
                }

                Spacer()

                Text(relativeDate(item.savedAt))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(BrandPalette.ink4)
            }

            Text(item.question)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(BrandPalette.ink)
                .lineLimit(2)
                .lineSpacing(2)

            HStack(spacing: 6) {
                DailyDevChip(item.tag, tone: .outline, size: .sm)

                let answer = correctAnswerLabel(item)
                if !answer.isEmpty {
                    Text("정답: \(answer)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(BrandPalette.greenInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(BrandPalette.greenSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            if !item.explanation.isEmpty {
                Text(item.explanation)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundStyle(BrandPalette.ink3)
                    .lineLimit(2)
                    .lineSpacing(2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(BrandPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(BrandPalette.line, lineWidth: 1))
    }

    private func typeTag(_ type: String) -> some View {
        let (label, color): (String, Color) = switch type {
        case "mcq":
            ("MCQ",  Color(red: 0.17, green: 0.39, blue: 0.92))
        case "ox":
            ("OX", BrandPalette.green)
        default:
            ("빈칸", Color(red: 0.88, green: 0.52, blue: 0.0))
        }
        return Text(label)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .frame(width: 34, height: 22)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func correctAnswerLabel(_ item: SavedQuizQuestion) -> String {
        switch item.questionType {
        case "ox":
            return item.oxAnswer
        case "fill":
            return item.fillAnswer
        case "mcq":
            let indices = item.resolvedCorrectIndices.filter { $0 >= 0 && $0 < item.choices.count }
            guard !indices.isEmpty else { return "" }
            return indices
                .map { i in "\(String(UnicodeScalar(65 + i)!)). \(item.choices[i])" }
                .joined(separator: ", ")
        default:
            return ""
        }
    }

    // MARK: - Posts

    private var postList: some View {
        Group {
            if posts.isEmpty {
                emptyState(
                    icon: "doc.text",
                    title: "저장된 글이 없어요",
                    subtitle: "Post에서 좌→우 스와이프로 저장해보세요"
                )
            } else {
                List {
                    ForEach(posts) { item in
                        postRow(item)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 4, trailing: 24))
                            .swipeActions(edge: .trailing) { deleteButton(item) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func postRow(_ item: SavedPost) -> some View {
        let url = URL(string: item.articleLink)
        return Button {
            if let url { webDestination = WebDestination(url: url) }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.blogName)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundStyle(BrandPalette.green)

                    Text(item.title)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(BrandPalette.ink)
                        .lineLimit(2)
                        .lineSpacing(2)

                    Text(relativeDate(item.savedAt))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(BrandPalette.ink4)
                }

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(BrandPalette.ink3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(BrandPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(BrandPalette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(url == nil)
    }

    // MARK: - Shared helpers

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(BrandPalette.ink4)
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BrandPalette.ink2)
                Text(subtitle)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundStyle(BrandPalette.ink3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }

    @ViewBuilder
    private func deleteButton(_ item: SavedConcept) -> some View {
        Button(role: .destructive) { modelContext.delete(item) } label: {
            Label("삭제", systemImage: "trash")
        }
    }

    @ViewBuilder
    private func deleteButton(_ item: SavedQuizQuestion) -> some View {
        Button(role: .destructive) { modelContext.delete(item) } label: {
            Label("삭제", systemImage: "trash")
        }
    }

    @ViewBuilder
    private func deleteButton(_ item: SavedPost) -> some View {
        Button(role: .destructive) { modelContext.delete(item) } label: {
            Label("삭제", systemImage: "trash")
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
#endif
