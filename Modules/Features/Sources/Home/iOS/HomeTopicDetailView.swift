#if os(iOS)
import SwiftUI
import ComposableArchitecture
import DesignSystem
import Entity

struct HomeTopicDetailView: View {
    @Bindable var store: StoreOf<HomeFeature>
    let categoryID: String
    let onSelectLesson: (String) -> Void

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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 48) {
                tableOfContentsSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(BrandPalette.background.ignoresSafeArea())
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if store.selectedCategoryID != categoryID {
                store.send(.categorySelected(categoryID))
            }
        }
    }

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
        store.categories.first(where: { $0.id == categoryID })?.title ?? "Computer Science"
    }

    private var tableOfContentsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("TABLE OF CONTENTS")
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Color(red: 0.36, green: 0.37, blue: 0.39))

                Spacer()

                Text("\(presentation.chapterRows.count) Chapters")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(red: 0.26, green: 0.28, blue: 0.33))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Color(red: 0.91, green: 0.91, blue: 0.93))
                    )
            }
            .padding(.horizontal, 8)

            if presentation.isCategoryLoading {
                ProgressView("불러오는 중")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 12) {
                ForEach(presentation.chapterRows) { row in
                    Button {
                        onSelectLesson(row.id)
                    } label: {
                        chapterRow(row)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let message = presentation.categoryErrorMessage {
                Text(message)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.red)
            }
        }
    }

    private func chapterRow(_ row: ChapterRow) -> some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.97, green: 0.98, blue: 0.99))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: row.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.38, green: 0.44, blue: 0.53))
                }

            Text(row.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(red: 0.10, green: 0.11, blue: 0.12))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(red: 0.76, green: 0.79, blue: 0.85))
        }
        .padding(17)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#endif
