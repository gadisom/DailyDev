#if os(iOS)
import SwiftUI
import ComposableArchitecture
import DesignSystem

struct HomeIOSContainer: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        NavigationStack {
            List {
                Section("카테고리") {
                    if store.categories.isEmpty {
                        Text("카테고리가 없습니다.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(store.categories) { category in
                        Button {
                            store.send(.categorySelected(category.id))
                        } label: {
                            HStack {
                                Text(category.title)
                                Spacer()
                                if store.selectedCategoryID == category.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(BrandPalette.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("요약") {
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
            }
            .navigationTitle(store.environment.appName)
        }
    }

    private var summaryText: String {
        guard let content = store.selectedContent else {
            return "카테고리를 선택하면 상세 내용이 아래에 보여집니다."
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

struct HomeIOSContainer: View {
    let store: StoreOf<HomeFeature>

    var body: some View {
        EmptyView()
    }
}
#endif
