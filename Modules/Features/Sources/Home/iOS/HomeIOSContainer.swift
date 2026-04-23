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
            BrandPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    subjectsSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                }
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DailyDev")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(BrandPalette.green)
                .tracking(1.4)
                .textCase(.uppercase)

            Text("Core Disciplines")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(BrandPalette.ink)
                .lineSpacing(2)
                .padding(.top, 10)

        }
    }

    // MARK: - Subjects list

    private var subjectsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Subjects")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(BrandPalette.ink3)

                Spacer()

                Text("\(cards.count) areas")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(BrandPalette.ink3)
            }
            .padding(.bottom, 2)

            if store.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(BrandPalette.green)
                    Text("콘텐츠 불러오는 중")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BrandPalette.ink3)
                }
                .padding(.top, 6)
                .padding(.bottom, 8)
            }

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BrandPalette.danger)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(BrandPalette.dangerSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if cards.isEmpty && !store.isLoading && store.errorMessage == nil {
                Text("카테고리를 가져오지 못했어요.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BrandPalette.ink3)
            }

            ForEach(cards) { card in
                Button {
                    if let id = card.categoryID {
                        onSelectCategory(id)
                    }
                } label: {
                    disciplineRow(card)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private func disciplineRow(_ card: CurriculumCard) -> some View {
        HStack(spacing: 14) {
            Image(systemName: card.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(card.iconColor)
                .frame(width: 42, height: 42)
                .background(card.iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(card.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(BrandPalette.ink)
                Text(card.englishName)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(BrandPalette.ink3)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BrandPalette.ink4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(BrandPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(BrandPalette.line, lineWidth: 1)
        )
    }

    // MARK: - Data

    private var cards: [CurriculumCard] {
        HomeIOSPresentationBuilder.displayCards(
            categories: store.categories,
            selectedCategoryID: store.selectedCategoryID,
            selectedContent: store.selectedContent
        )
    }
}
#endif
