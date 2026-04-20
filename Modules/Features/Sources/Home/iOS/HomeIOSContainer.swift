#if os(iOS)
import SwiftUI
import ComposableArchitecture
import DesignSystem
import Entity

struct HomeIOSContainer: View {
    @Bindable var store: StoreOf<HomeFeature>
    let onSelectCategory: (String) -> Void

    init(
        store: StoreOf<HomeFeature>,
        onSelectCategory: @escaping (String) -> Void = { _ in }
    ) {
        self.store = store
        self.onSelectCategory = onSelectCategory
    }

    var body: some View {
        ZStack {
            BrandPalette.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 48) {
                    curriculumSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 28)
            }
        }
    }

    private var curriculumSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                DailyDevSectionTitle("CURRICULUM")

                Text("Core Disciplines")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
            }

            VStack(spacing: 0) {
                ForEach(Array(displayCards.enumerated()), id: \.element.id) { index, card in
                    Button {
                        if let categoryID = card.categoryID {
                            onSelectCategory(categoryID)
                        }
                    } label: {
                        simpleRow(title: card.title)
                    }
                    .buttonStyle(.plain)

                    if index < displayCards.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
        }
    }

    private func simpleRow(title: String) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0.68, green: 0.72, blue: 0.79))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    private var displayCards: [CurriculumCard] {
        HomeIOSPresentationBuilder.displayCards(
            categories: store.categories,
            selectedCategoryID: store.selectedCategoryID,
            selectedContent: store.selectedContent
        )
    }
}
#endif
