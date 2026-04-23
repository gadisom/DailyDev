#if os(iOS)
import SwiftUI
import SwiftData
import ComposableArchitecture
import DesignSystem

struct HomeLessonDetailView: View {
    @Bindable var store: StoreOf<HomeFeature>
    let categoryID: String
    let subcategoryID: String
    let onSelectNextLesson: (String) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var savedConcepts: [SavedConcept]

    private enum Layout {
        static let rootGap: CGFloat = Spacing.section
        static let horizontalPadding: CGFloat = Spacing.xl
        static let verticalPadding: CGFloat = 40
        static let sectionGap: CGFloat = Spacing.xl
        static let keypointSectionGap: CGFloat = Spacing.xxl
        static let pointSpacing: CGFloat = 8
        static let imageGap: CGFloat = Spacing.sm
        static let imageHeight: CGFloat = 220
        static let imageCardSpacing: CGFloat = Spacing.xs
        static let cardHeaderPadding: CGFloat = Spacing.md
        static let checklistRowPadding: CGFloat = Spacing.md
        static let checklistCornerRadius: CGFloat = Radius.md
        static let checklistBorderRadius: CGFloat = Radius.sm
        static let nextLessonPadding: CGFloat = Spacing.xxl
        static let pillWidth: CGFloat = 48
        static let pillHeight: CGFloat = 4
        static let badgeRadius: CGFloat = Radius.pill
    }

    init(
        store: StoreOf<HomeFeature>,
        categoryID: String,
        subcategoryID: String,
        onSelectNextLesson: @escaping (String) -> Void = { _ in }
    ) {
        self.store = store
        self.categoryID = categoryID
        self.subcategoryID = subcategoryID
        self.onSelectNextLesson = onSelectNextLesson
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.rootGap) {
                lessonHeaderSection
                orderedContentSection

                if let nextLesson = presentation.nextLessonRow {
                    nextLessonButton(nextLesson)
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, Layout.verticalPadding)
            .padding(.bottom, Layout.verticalPadding)
            .frame(maxWidth: 512, alignment: .leading)
        }
        .background(BrandPalette.background.ignoresSafeArea())
        .navigationTitle(presentation.lessonTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { toggleBookmark() } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                }
                .tint(isBookmarked ? BrandPalette.green : BrandPalette.ink3)
            }
        }
        .task {
            if store.selectedCategoryID != categoryID {
                store.send(.categorySelected(categoryID))
            }
        }
    }

    private var presentation: HomeLessonPresentation {
        HomeIOSPresentationBuilder.lesson(
            categoryID: categoryID,
            subcategoryID: subcategoryID,
            categories: store.categories,
            selectedCategoryID: store.selectedCategoryID,
            selectedContent: store.selectedContent
        )
    }

    private var isBookmarked: Bool {
        savedConcepts.contains { $0.conceptID == subcategoryID }
    }

    private func toggleBookmark() {
        if let existing = savedConcepts.first(where: { $0.conceptID == subcategoryID }) {
            modelContext.delete(existing)
        } else {
            let concept = SavedConcept(
                conceptID: subcategoryID,
                title: presentation.lessonTitle,
                categoryID: categoryID,
                categoryTitle: presentation.lessonBadgeText,
                summary: presentation.definitionHeadline
            )
            modelContext.insert(concept)
        }
    }

    @ViewBuilder
    private var orderedContentSection: some View {
        VStack(alignment: .leading, spacing: Layout.sectionGap) {
            ForEach(Array(presentation.contentBlocks.enumerated()), id: \.element.id) { index, block in
                lessonContentBlockView(block)

                if index < presentation.contentBlocks.count - 1 {
                    separator
                }
            }
        }
    }

    @ViewBuilder
    private func lessonContentBlockView(_ block: LessonContentBlock) -> some View {
        switch block.kind {
        case .definition:
            definitionBlock(items: block.items)
        case .image:
            imageBlock(urls: block.imageURLs)
        case .keyPoints:
            keyPointsBlock(items: block.items)
        case .interviewPrompts:
            checklistCard(title: "INTERVIEW PROMPTS", items: block.items)
        case .checkQuestions:
            checklistCard(title: "CHECK QUESTIONS", items: block.items)
        case .other:
            genericTextBlock(items: block.items)
        }
    }

    private func definitionBlock(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            DailyDevSectionTitle("DEFINITION")

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Text(item)
                    .font(DailyDevTypography.body16)
                    .lineSpacing(7)
                    .foregroundStyle(BrandPalette.ink2)
            }
        }
    }

    private func keyPointsBlock(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: Layout.sectionGap) {
            DailyDevSectionTitle("KEY CHARACTERISTICS")

            VStack(alignment: .leading, spacing: Layout.keypointSectionGap) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, point in
                    VStack(alignment: .leading, spacing: Layout.pointSpacing) {
                        let number = index + 1 < 10 ? "0\(index + 1)" : "\(index + 1)"

                        Text("POINT \(number)")
                            .font(DailyDevTypography.title16)
                            .foregroundStyle(BrandPalette.ink)

                        Text(point)
                            .font(DailyDevTypography.bodySmall)
                            .lineSpacing(6)
                            .foregroundStyle(BrandPalette.ink2)
                    }
                }
            }
        }
    }

    private func imageBlock(urls: [URL]) -> some View {
        VStack(spacing: Layout.imageGap) {
            ForEach(Array(urls.enumerated()), id: \.offset) { _, imageURL in
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: Layout.imageHeight)
                    case .failure:
                        EmptyView()
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: Layout.imageHeight)
                            .tint(BrandPalette.green)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
    }

    private func genericTextBlock(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: Layout.imageCardSpacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Text(item)
                    .font(DailyDevTypography.body)
                    .lineSpacing(6)
                    .foregroundStyle(BrandPalette.ink2)
            }
        }
    }

    private var lessonHeaderSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(presentation.lessonBadgeText)
                .font(DailyDevTypography.labelSmall)
                .tracking(1.1)
                .foregroundStyle(BrandPalette.green)

            Text(presentation.lessonTitle)
                .font(DailyDevTypography.displayRoundedLarge)
                .foregroundStyle(BrandPalette.ink)

            RoundedRectangle(cornerRadius: Layout.badgeRadius)
                .fill(BrandPalette.green)
                .frame(width: Layout.pillWidth, height: Layout.pillHeight)
        }
    }

    private func nextLessonButton(_ nextLesson: ChapterRow) -> some View {
        Button {
            onSelectNextLesson(nextLesson.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NEXT LESSON")
                        .font(DailyDevTypography.captionBold)
                        .tracking(2)
                        .foregroundStyle(BrandPalette.ink3)

                    Text(nextLesson.title)
                        .font(DailyDevTypography.title20)
                        .foregroundStyle(BrandPalette.ink)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(DailyDevTypography.title20)
                    .foregroundStyle(BrandPalette.green)
            }
            .padding(Layout.nextLessonPadding)
            .overlay {
                RoundedRectangle(cornerRadius: Layout.checklistBorderRadius)
                    .stroke(BrandPalette.line, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func checklistCard(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(DailyDevTypography.label)
                .tracking(0.8)
                .foregroundStyle(BrandPalette.ink3)
                .padding(Layout.cardHeaderPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BrandPalette.surfaceAlt)

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(DailyDevTypography.monoBold12)
                        .foregroundStyle(BrandPalette.green)

                    Text(item)
                        .font(DailyDevTypography.bodySmall)
                        .lineSpacing(5)
                        .foregroundStyle(BrandPalette.ink)
                }
                .padding(Layout.checklistRowPadding)
                .overlay(alignment: .top) {
                    if index > 0 {
                        Divider().background(BrandPalette.line)
                    }
                }
            }
        }
        .background(BrandPalette.surface)
        .overlay {
            RoundedRectangle(cornerRadius: Layout.checklistCornerRadius)
                .stroke(BrandPalette.line, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: Layout.checklistCornerRadius))
    }

    private var separator: some View {
        Rectangle()
            .fill(BrandPalette.line)
            .frame(height: 1)
    }
}
#endif
