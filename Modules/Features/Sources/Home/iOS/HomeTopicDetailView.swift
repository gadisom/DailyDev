#if os(iOS)
import SwiftUI
import ComposableArchitecture
import DesignSystem
import Entity

struct HomeTopicDetailView: View {
    @Bindable var store: StoreOf<HomeFeature>
    let categoryID: String
    let onSelectLesson: (String) -> Void

    private enum Layout {
        static let screenMargin: CGFloat = Spacing.screenEdge
        static let bottomPadding: CGFloat = Spacing.section
        static let headerBottomSpacing: CGFloat = 2
        static let loadingTextTopPadding: CGFloat = Spacing.sm
        static let errorTopPadding: CGFloat = Spacing.sm - Spacing.xxs
        static let chapterBadgeWidth: CGFloat = 36
        static let chapterBadgeHeight: CGFloat = 36
        static let chapterBadgeCornerRadius: CGFloat = Radius.sm
        static let chapterRowSpacing: CGFloat = 14
        static let chapterRowPadding: CGFloat = Spacing.md
        static let chapterTitleFont = DailyDevTypography.monoLabel10
        static let chapterNumberFont = DailyDevTypography.mono
    }

    init(
        store: StoreOf<HomeFeature>,
        categoryID: String,
        onSelectLesson: @escaping (String) -> Void = { _ in }
    ) {
        self.store = store
        self.categoryID = categoryID
        self.onSelectLesson = onSelectLesson
    }

    var body: some View {
        ZStack {
            BrandPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    tocSection
                        .padding(.horizontal, Layout.screenMargin)
                        .padding(.top, Layout.screenMargin)
                }
                .padding(.bottom, Layout.bottomPadding)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if store.selectedCategoryID != categoryID {
                store.send(.categorySelected(categoryID))
            }
        }
    }

    // MARK: - Data

    private var presentation: HomeTopicPresentation {
        HomeIOSPresentationBuilder.topic(
            categoryID: categoryID,
            categories: store.categories,
            selectedCategoryID: store.selectedCategoryID,
            selectedContent: store.selectedContent,
            isLoading: store.isLoading,
            errorMessage: store.errorMessage
        )
    }

    private var navigationTitle: String {
        store.categories.first(where: { $0.id == categoryID })?.title ?? "카테고리"
    }

    // MARK: - Table of contents

    private var tocSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Table of Contents")
                    .font(DailyDevTypography.labelSmall)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(BrandPalette.ink3)

                Spacer()

                Text("\(presentation.chapterRows.count) Chapters")
                    .font(DailyDevTypography.label)
                    .foregroundStyle(BrandPalette.ink2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, Spacing.xxs / 2)
                    .background(BrandPalette.surfaceAlt)
                    .clipShape(Capsule())
            }
            .padding(.bottom, Layout.headerBottomSpacing)

            if presentation.isCategoryLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(BrandPalette.green)
                    Text("불러오는 중")
                        .font(DailyDevTypography.bodySmallRegular)
                        .foregroundStyle(BrandPalette.ink3)
                }
                .padding(.top, Layout.loadingTextTopPadding)
            }

            if !presentation.isCategoryLoading && presentation.chapterRows.isEmpty && store.errorMessage == nil {
                Text("하위 목차가 없습니다.")
                    .font(DailyDevTypography.bodySmallRegular)
                    .foregroundStyle(BrandPalette.ink3)
            }

            ForEach(Array(presentation.chapterRows.enumerated()), id: \.element.id) { index, row in
                Button {
                    onSelectLesson(row.id)
                } label: {
                    chapterRow(row, index: index)
                }
                .buttonStyle(ScaleButtonStyle())
            }

            if let message = presentation.categoryErrorMessage {
                Text(message)
                    .font(DailyDevTypography.bodySmallRegular)
                    .foregroundStyle(BrandPalette.danger)
                    .padding(.top, Layout.errorTopPadding)
            }
        }
    }

    private func chapterRow(_ row: ChapterRow, index: Int) -> some View {
        let num = String(format: "%02d", index + 1)

        return HStack(spacing: Layout.chapterRowSpacing) {

            // Chapter number badge
            Text(num)
                .font(Layout.chapterNumberFont)
                .foregroundStyle(BrandPalette.ink3)
                .frame(width: Layout.chapterBadgeWidth, height: Layout.chapterBadgeHeight)
                .background(BrandPalette.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: Layout.chapterBadgeCornerRadius))

            // Labels
            VStack(alignment: .leading, spacing: 2) {
                Text("Chapter \(num)")
                    .font(Layout.chapterTitleFont)
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .foregroundStyle(BrandPalette.ink4)

                Text(row.title)
                    .font(DailyDevTypography.label)
                    .foregroundStyle(BrandPalette.ink)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(DailyDevTypography.label)
                .foregroundStyle(BrandPalette.ink4)
        }
        .padding(Layout.chapterRowPadding)
        .background(BrandPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(BrandPalette.line, lineWidth: 1)
        )
    }
}
#endif
