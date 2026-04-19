#if os(macOS)
import SwiftUI
import ComposableArchitecture
import DesignSystem

struct HomeMacView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(store.categories) { category in
                    Button {
                        store.send(.categorySelected(category.id))
                    } label: {
                        HStack {
                            Text(category.title)
                            Spacer()
                            if store.selectedCategoryID == category.id {
                                Image(systemName: "book.fill")
                                    .foregroundStyle(BrandPalette.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(store.environment.appName)
        } detail: {
            VStack(alignment: .leading, spacing: 24) {
                Text(store.selectedContent?.title ?? "CS 리소스")
                    .font(.dailyDevTitle)
                    .foregroundStyle(BrandPalette.textPrimary)

                if store.isLoading {
                    ProgressView("데이터 준비 중")
                } else {
                    Text(summaryText)
                        .font(.dailyDevBody)
                        .foregroundStyle(BrandPalette.textSecondary)
                }

                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(.dailyDevBody)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(32)
            .background(BrandPalette.background)
        }
    }

    private var summaryText: String {
        guard let content = store.selectedContent else {
            return "좌측 카테고리를 선택하면 상세 데이터를 표시합니다."
        }

        let subcategoryCount = content.subcategories.count
        let itemCount = content.subcategories.reduce(0) { $0 + $1.items.count }
        let versionText = store.manifest.map { " (manifest v\($0.version))" } ?? ""
        return "\(content.title) / 하위분류 \(subcategoryCount)개, 항목 \(itemCount)개\(versionText)"
    }
}
#else
import SwiftUI
import ComposableArchitecture

struct HomeMacView: View {
    let store: StoreOf<HomeFeature>

    var body: some View {
        EmptyView()
    }
}
#endif
