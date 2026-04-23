import ComposableArchitecture
import Entity
import SwiftUI
import SwiftData
import DesignSystem

struct PostView: View {
    @Bindable var store: StoreOf<PostFeature>
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Query private var savedPosts: [SavedPost]

    private enum Layout {
        static let sectionSpacing: CGFloat = Spacing.sm
        static let listVerticalSpacing: CGFloat = Spacing.sm
        static let chipPaddingH: CGFloat = Spacing.md
        static let chipPaddingV: CGFloat = Spacing.xs
        static let chipSpacing: CGFloat = Spacing.sm
        static let filterBarPaddingH: CGFloat = Spacing.md
        static let filterBarPaddingV: CGFloat = Spacing.sm
        static let reconnectIconSize: CGFloat = 13
        static let listSidePadding: CGFloat = Spacing.md
        static let listItemCornerRadius: CGFloat = Radius.md
        static let listItemGap: CGFloat = Spacing.xxs
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                switch store.phase {
                case .idle, .loading:
                    if store.articles.isEmpty {
                        loadingBody
                    } else {
                        listBody
                    }
                case .content, .reconnecting:
                    listBody
                case .empty:
                    emptyBody
                case .error:
                    errorBody
                }
            }
            .background(BrandPalette.background.ignoresSafeArea())
            .navigationTitle("Tech Posts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BrandPalette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .refreshable {
                store.send(.refreshRequested)
            }
            .tint(BrandPalette.green)
        }
    }

    @ViewBuilder
    private var loadingBody: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("글 목록을 불러오는 중...")
                .font(DailyDevTypography.bodySmallRegular)
                .foregroundStyle(BrandPalette.ink3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private var emptyBody: some View {
        VStack(spacing: 12) {
            Text("글이 없습니다.")
                .font(DailyDevTypography.title3)
                .foregroundStyle(BrandPalette.ink)
            Text("다시 불러오려면 새로고침을 눌러주세요.")
                .font(DailyDevTypography.bodySmallRegular)
                .foregroundStyle(BrandPalette.ink3)
            Button("다시 시도") {
                store.send(.retryTapped)
            }
            .disabled(!store.canRetry)
            .font(DailyDevTypography.label)
            .foregroundStyle(BrandPalette.surfaceWhite)
            .padding(.horizontal, Layout.chipPaddingH)
            .padding(.vertical, Layout.chipPaddingV)
            .background(BrandPalette.green)
            .clipShape(Capsule())
            .opacity(store.canRetry ? 1 : 0.45)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private var errorBody: some View {
        VStack(spacing: 12) {
            Text("문제가 발생했습니다")
                .font(DailyDevTypography.title3)
                .foregroundStyle(BrandPalette.ink)
            Text(store.message)
                .font(DailyDevTypography.bodySmallRegular)
                .foregroundStyle(BrandPalette.ink3)
                .multilineTextAlignment(.center)
            Button("다시 시도") {
                store.send(.retryTapped)
            }
            .disabled(!store.canRetry)
            .font(DailyDevTypography.label)
            .foregroundStyle(BrandPalette.surfaceWhite)
            .padding(.horizontal, Layout.chipPaddingH)
            .padding(.vertical, Layout.chipPaddingV)
            .background(BrandPalette.green)
            .clipShape(Capsule())
            .opacity(store.canRetry ? 1 : 0.45)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private var listBody: some View {
        List {
            if !store.message.isEmpty && store.phase == .reconnecting {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: Layout.reconnectIconSize, weight: .semibold))
                            .foregroundStyle(BrandPalette.green)
                        Text(store.message)
                            .font(DailyDevTypography.bodySmallRegular)
                            .foregroundStyle(BrandPalette.ink3)
                        Spacer()
                        if store.canRetry {
                            Button("재시도") {
                                store.send(.retryTapped)
                            }
                            .font(DailyDevTypography.monoCaption)
                            .foregroundStyle(BrandPalette.green)
                        }
                    }
                    .padding(.vertical, Layout.listVerticalSpacing)
                    .padding(.horizontal, Layout.listSidePadding)
                    .background(BrandPalette.background)
                }
            }

            if store.visibleArticles.isEmpty && !store.articles.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("선택한 필터에 맞는 글이 아직 없어요.")
                            .font(DailyDevTypography.bodySmallRegular)
                            .foregroundStyle(BrandPalette.ink3)
                        if store.hasNext {
                            Button("더 불러오기") {
                                store.send(.loadMoreTapped)
                            }
                            .font(DailyDevTypography.label)
                            .foregroundStyle(BrandPalette.green)
                            .padding(.horizontal, Layout.chipPaddingH)
                            .padding(.vertical, Layout.chipPaddingV)
                            .background(BrandPalette.surfaceSoft)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, Layout.listVerticalSpacing)
                }
            }

            ForEach(store.visibleArticles) { article in
                Button {
                    openArticle(article.articleLink)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.blogName)
                            .font(DailyDevTypography.monoCaption)
                            .foregroundStyle(BrandPalette.green)
                        Text(article.title)
                            .font(DailyDevTypography.body)
                            .foregroundStyle(BrandPalette.ink)
                        Text(formatPublishedDate(for: article))
                            .font(DailyDevTypography.monoCaption)
                            .foregroundStyle(BrandPalette.ink3)
                    }
                    .padding(.vertical, Layout.listVerticalSpacing)
                    .padding(.horizontal, Layout.listSidePadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.listItemCornerRadius)
                            .fill(BrandPalette.surface)
                    )
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .disabled(URL(string: article.articleLink) == nil)
                .swipeActions(edge: .leading) {
                    let isSaved = savedPosts.contains { $0.articleID == article.id }
                    if isSaved {
                        Button {
                            if let existing = savedPosts.first(where: { $0.articleID == article.id }) {
                                modelContext.delete(existing)
                            }
                        } label: {
                            Label("저장 취소", systemImage: "bookmark.slash")
                        }
                        .tint(.orange)
                    } else {
                        Button {
                            modelContext.insert(SavedPost(from: article))
                        } label: {
                            Label("저장", systemImage: "bookmark")
                        }
                        .tint(BrandPalette.green)
                    }
                }
                .onAppear {
                    store.send(.rowAppeared(article.id))
                }
            }

            if store.phase == .reconnecting || (store.isLoading && !store.articles.isEmpty) {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(BrandPalette.green)
                    Spacer()
                }
                .padding(.vertical, Layout.sectionSpacing)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listRowSpacing(Layout.listItemGap)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Layout.chipSpacing) {
                ForEach(store.filterChips) { chip in
                    filterChip(for: chip)
                }
            }
        .padding(.horizontal, Layout.filterBarPaddingH)
        .padding(.vertical, Layout.filterBarPaddingV)
        }
        .background(BrandPalette.background)
    }

    private func filterChip(for chip: PostFeature.State.FilterChip) -> some View {
        let isSelected = store.selectedFilterID == chip.id

        return Button {
            store.send(.filterSelected(chip.id))
        } label: {
            Text(chip.title)
                .font(DailyDevTypography.label)
                .foregroundStyle(isSelected ? BrandPalette.surfaceWhite : BrandPalette.green)
                .padding(.horizontal, Layout.chipPaddingH)
                .padding(.vertical, Layout.chipPaddingV)
                .background(isSelected ? BrandPalette.green : BrandPalette.surfaceSoft)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? BrandPalette.green : BrandPalette.surfaceOutline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func formatPublishedDate(for item: PostArticleListItem) -> String {
        let seconds = TimeInterval(item.publishedAtMillis) / 1000.0
        let date = Date(timeIntervalSince1970: seconds)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func openArticle(_ stringURL: String) {
        guard let url = URL(string: stringURL) else { return }
        openURL(url)
    }
}
