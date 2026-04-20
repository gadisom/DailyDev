#if os(iOS)
import SwiftUI
import ComposableArchitecture
import DesignSystem
import Entity

private enum HomeIOSRoute: Hashable {
    case category(String)
    case lesson(categoryID: String, subcategoryID: String)
}

struct HomeIOSCoordinator: View {
    @Bindable var store: StoreOf<HomeFeature>
    @State private var path: [HomeIOSRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeIOSContainer(store: store) { categoryID in
                if store.selectedCategoryID != categoryID {
                    store.send(.categorySelected(categoryID))
                }
                path.append(.category(categoryID))
            }
            .navigationDestination(for: HomeIOSRoute.self) { route in
                switch route {
                case let .category(categoryID):
                    HomeTopicDetailView(store: store, categoryID: categoryID) { subcategoryID in
                        path.append(.lesson(categoryID: categoryID, subcategoryID: subcategoryID))
                    }
                case let .lesson(categoryID, subcategoryID):
                    HomeLessonDetailView(
                        store: store,
                        categoryID: categoryID,
                        subcategoryID: subcategoryID
                    ) { nextSubcategoryID in
                        path.append(.lesson(categoryID: categoryID, subcategoryID: nextSubcategoryID))
                    }
                }
            }
        }
    }
}

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
                    searchSection
                    curriculumSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 28)
            }
        }
    }

    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color(red: 0.58, green: 0.64, blue: 0.72))

            Text("Search concepts, topics, or definitions...")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color(red: 0.58, green: 0.64, blue: 0.72))

            Spacer(minLength: 0)
        }
        .padding(.vertical, 18)
        .padding(.leading, 14)
        .padding(.trailing, 24)
        .background(Color(red: 0.91, green: 0.91, blue: 0.93))
        .clipShape(Capsule())
    }

    private var curriculumSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRICULUM")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color(red: 0.0, green: 0.35, blue: 0.74))

                Text("Core Disciplines")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
            }

            VStack(spacing: 24) {
                ForEach(Array(displayCards.enumerated()), id: \.element.id) { index, card in
                    Button {
                        if let categoryID = card.categoryID {
                            onSelectCategory(categoryID)
                        }
                    } label: {
                        if index < 2 {
                            featuredCard(card)
                        } else {
                            compactCard(card)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func featuredCard(_ card: CurriculumCard) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(card.iconBackground)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: card.icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(card.iconColor)
                    }

                Text(card.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
            }

            HStack(spacing: 8) {
                ForEach(card.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Color(red: 0.39, green: 0.45, blue: 0.55))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.93, green: 0.93, blue: 0.95))
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 4)
    }

    private func compactCard(_ card: CurriculumCard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(card.iconBackground)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: card.icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(card.iconColor)
                }

            Text(card.title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 4)
    }

    private var displayCards: [CurriculumCard] {
        let sortedCategories = store.categories.sorted { $0.displayOrder < $1.displayOrder }

        guard !sortedCategories.isEmpty else {
            return CurriculumCard.defaults
        }

        return sortedCategories.enumerated().map { index, category in
            let style = CurriculumCard.styles[index % CurriculumCard.styles.count]

            return CurriculumCard(
                id: category.id,
                categoryID: category.id,
                title: category.title,
                description: description(for: category.id, fallback: style.defaultDescription),
                tags: tags(for: category.id, fallback: style.defaultTags),
                icon: style.icon,
                iconBackground: style.iconBackground,
                iconColor: style.iconColor
            )
        }
    }

    private func description(for categoryID: String, fallback: String) -> String {
        guard
            let category = store.categories.first(where: { $0.id == categoryID }),
            let content = store.selectedCategoryID == category.id
                ? store.selectedContent
                : nil,
            let firstSubcategory = content.subcategories
                .sorted(by: { $0.displayOrder < $1.displayOrder })
                .first,
            let firstItem = firstSubcategory.items
                .sorted(by: { $0.displayOrder < $1.displayOrder })
                .first
        else {
            return fallback
        }

        return firstItem.summary
    }

    private func tags(for categoryID: String, fallback: [String]) -> [String] {
        guard
            let category = store.categories.first(where: { $0.id == categoryID }),
            let content = store.selectedCategoryID == category.id
                ? store.selectedContent
                : nil
        else {
            return fallback
        }

        let keywords = content.subcategories
            .sorted(by: { $0.displayOrder < $1.displayOrder })
            .flatMap { subcategory in
                subcategory.items
                    .sorted(by: { $0.displayOrder < $1.displayOrder })
                    .flatMap { $0.keywords }
            }

        let unique = Array(Set(keywords.map { $0.uppercased() })).sorted()
        let prefix = Array(unique.prefix(2))

        guard !prefix.isEmpty else { return fallback }

        if unique.count > 2 {
            return prefix + ["+\(unique.count - 2) MORE"]
        }

        return prefix
    }
}

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
                heroSection
                tableOfContentsSection
                indexSummarySection
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(BrandPalette.background.ignoresSafeArea())
        .navigationTitle("Computer Science")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "bookmark")
                }
                .tint(Color(red: 0.39, green: 0.45, blue: 0.55))

                Button {} label: {
                    Image(systemName: "ellipsis")
                }
                .tint(Color(red: 0.39, green: 0.45, blue: 0.55))
            }
        }
        .task {
            if store.selectedCategoryID != categoryID {
                store.send(.categorySelected(categoryID))
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(titleForHero)
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .lineSpacing(-2)
                .foregroundStyle(Color(red: 0.10, green: 0.11, blue: 0.12))

            VStack(alignment: .leading, spacing: 24) {
                Text(summaryText)
                    .font(.system(size: 16, weight: .regular))
                    .lineSpacing(8)
                    .foregroundStyle(Color(red: 0.26, green: 0.28, blue: 0.33))
            }
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 18, x: 0, y: 12)
            }
        }
    }

    private var tableOfContentsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("TABLE OF CONTENTS")
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Color(red: 0.36, green: 0.37, blue: 0.39))

                Spacer()

                Text("\(chapterRows.count) Chapters")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(red: 0.26, green: 0.28, blue: 0.33))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Color(red: 0.91, green: 0.91, blue: 0.93))
                    )
            }
            .padding(.horizontal, 8)

            if isCategoryLoading {
                ProgressView("불러오는 중")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 12) {
                ForEach(chapterRows) { row in
                    Button {
                        onSelectLesson(row.id)
                    } label: {
                        chapterRow(row)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let message = categoryErrorMessage {
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

    private var indexSummarySection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("INDEX SUMMARY")
                .font(.system(size: 14, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Color(red: 0.36, green: 0.37, blue: 0.39))
                .padding(.horizontal, 8)

            VStack(spacing: 16) {
                summaryHeroCard

                HStack(spacing: 16) {
                    summarySmallCard(number: diagramCountText, label: "DIAGRAMS")
                    summarySmallCard(number: algorithmCountText, label: "ALGORITHMS")
                }
            }
        }
    }

    private var summaryHeroCard: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.06, green: 0.09, blue: 0.16))

            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "book.pages")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pagesCountText)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text("PAGES OF REFERENCE")
                        .font(.system(size: 12, weight: .regular))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)

            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(red: 0.17, green: 0.24, blue: 0.38), lineWidth: 4)
                .frame(width: 80, height: 58)
                .offset(x: 16, y: 16)
        }
        .frame(height: 152)
    }

    private func summarySmallCard(number: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color(red: 0.10, green: 0.11, blue: 0.12))

            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color(red: 0.26, green: 0.28, blue: 0.33))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(red: 0.91, green: 0.91, blue: 0.93))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var currentCategoryTitle: String {
        store.categories.first(where: { $0.id == categoryID })?.title ?? "Data Structures"
    }

    private var titleForHero: String {
        let words = currentCategoryTitle.split(separator: " ")
        guard words.count > 1 else { return currentCategoryTitle }

        let midpoint = Int(ceil(Double(words.count) / 2.0))
        let firstLine = words.prefix(midpoint).joined(separator: " ")
        let secondLine = words.suffix(words.count - midpoint).joined(separator: " ")
        return "\(firstLine)\n\(secondLine)"
    }

    private var selectedCategoryContent: CSCategoryContent? {
        guard store.selectedCategoryID == categoryID else { return nil }
        return store.selectedContent
    }

    private var isCategoryLoading: Bool {
        store.isLoading && store.selectedCategoryID == categoryID
    }

    private var categoryErrorMessage: String? {
        guard store.selectedCategoryID == categoryID else { return nil }
        return store.errorMessage
    }

    private var summaryText: String {
        guard
            let content = selectedCategoryContent,
            let firstSubcategory = content.subcategories
                .sorted(by: { $0.displayOrder < $1.displayOrder })
                .first,
            let firstItem = firstSubcategory.items
                .sorted(by: { $0.displayOrder < $1.displayOrder })
                .first,
            !firstItem.summary.isEmpty
        else {
            return "Data structures are specialized formats for organizing, processing, retrieving, and storing data. They are the fundamental building blocks of efficient software, determining how information is navigated and manipulated across memory."
        }

        return firstItem.summary
    }

    private var chapterRows: [ChapterRow] {
        if let content = selectedCategoryContent {
            let sorted = content.subcategories.sorted(by: { $0.displayOrder < $1.displayOrder })

            if !sorted.isEmpty {
                return sorted.enumerated().map { index, subcategory in
                    ChapterRow(
                        id: subcategory.id,
                        title: subcategory.title,
                        icon: ChapterRow.icons[index % ChapterRow.icons.count]
                    )
                }
            }
        }

        return ChapterRow.defaults
    }

    private var pagesCountText: String {
        guard let content = selectedCategoryContent else { return "142" }

        let pages = content.subcategories.reduce(0) { result, subcategory in
            result + max(subcategory.items.count * 2, 1)
        }
        return "\(max(pages, 1))"
    }

    private var diagramCountText: String {
        guard let content = selectedCategoryContent else { return "24" }
        return "\(content.subcategories.count)"
    }

    private var algorithmCountText: String {
        guard let content = selectedCategoryContent else { return "12" }
        let itemCount = content.subcategories.reduce(0) { $0 + $1.items.count }
        return "\(itemCount)"
    }
}

struct HomeLessonDetailView: View {
    @Bindable var store: StoreOf<HomeFeature>
    let categoryID: String
    let subcategoryID: String
    let onSelectNextLesson: (String) -> Void

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
            VStack(alignment: .leading, spacing: 48) {
                lessonHeaderSection
                definitionSection
                separator
                keyCharacteristicsSection
                separator
                interviewPrepSection

                if let nextLesson = nextLessonRow {
                    nextLessonButton(nextLesson)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 40)
            .frame(maxWidth: 512, alignment: .leading)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle(lessonTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "bookmark")
                }
                .tint(Color(red: 0.39, green: 0.45, blue: 0.55))
            }
        }
        .task {
            if store.selectedCategoryID != categoryID {
                store.send(.categorySelected(categoryID))
            }
        }
    }

    private var lessonHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(lessonBadgeText)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.1)
                    .foregroundStyle(Color(red: 0.0, green: 0.35, blue: 0.74))

                Rectangle()
                    .fill(Color(red: 0.0, green: 0.35, blue: 0.74).opacity(0.2))
                    .frame(width: 32, height: 1)

                Text("LESSON \(lessonNumberText)")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.1)
                    .foregroundStyle(Color(red: 0.58, green: 0.64, blue: 0.72))
            }

            Text(lessonTitle)
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))

            RoundedRectangle(cornerRadius: 999)
                .fill(Color(red: 0.0, green: 0.35, blue: 0.74))
                .frame(width: 48, height: 4)
        }
    }

    private var definitionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("DEFINITION")

            if !definitionHeadline.isEmpty {
                Text(definitionHeadline)
                    .font(.system(size: 18, weight: .medium))
                    .lineSpacing(7)
                    .foregroundStyle(Color(red: 0.20, green: 0.26, blue: 0.33))
            }

            if !definitionBody.isEmpty {
                Text(definitionBody)
                    .font(.system(size: 16, weight: .regular))
                    .lineSpacing(7)
                    .foregroundStyle(Color(red: 0.28, green: 0.34, blue: 0.41))
            }

            if !keywordTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(keywordTags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(red: 0.0, green: 0.35, blue: 0.74))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(red: 0.94, green: 0.97, blue: 1.0))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var keyCharacteristicsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("KEY CHARACTERISTICS")

            VStack(alignment: .leading, spacing: 32) {
                ForEach(characteristics) { characteristic in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(characteristic.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))

                        Text(characteristic.description)
                            .font(.system(size: 14, weight: .regular))
                            .lineSpacing(6)
                            .foregroundStyle(Color(red: 0.28, green: 0.34, blue: 0.41))
                    }
                }
            }
        }
    }

    private var interviewPrepSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("INTERVIEW PREP")

            if !interviewPrompts.isEmpty {
                checklistCard(title: "INTERVIEW PROMPTS", items: interviewPrompts)
            }

            if !checkQuestions.isEmpty {
                checklistCard(title: "CHECK QUESTIONS", items: checkQuestions)
            }
        }
    }

    private func nextLessonButton(_ nextLesson: ChapterRow) -> some View {
        Button {
            onSelectNextLesson(nextLesson.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NEXT LESSON")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color(red: 0.58, green: 0.64, blue: 0.72))

                    Text(nextLesson.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(red: 0.0, green: 0.35, blue: 0.74))
            }
            .padding(24)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .tracking(1.3)
            .foregroundStyle(Color(red: 0.58, green: 0.64, blue: 0.72))
    }

    private func checklistCard(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Color(red: 0.39, green: 0.45, blue: 0.55))
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.97, green: 0.98, blue: 0.99))

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.0, green: 0.35, blue: 0.74))

                    Text(item)
                        .font(.system(size: 14, weight: .regular))
                        .lineSpacing(5)
                        .foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.23))
                }
                .padding(16)
                .overlay(alignment: .top) {
                    if index > 0 {
                        Divider().background(Color(red: 0.97, green: 0.98, blue: 0.99))
                    }
                }
            }
        }
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.95, green: 0.96, blue: 0.98), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var separator: some View {
        Rectangle()
            .fill(Color(red: 0.95, green: 0.96, blue: 0.98))
            .frame(height: 1)
    }

    private var selectedCategoryContent: CSCategoryContent? {
        guard store.selectedCategoryID == categoryID else { return nil }
        return store.selectedContent
    }

    private var chapterRows: [ChapterRow] {
        if let content = selectedCategoryContent {
            let sorted = content.subcategories.sorted(by: { $0.displayOrder < $1.displayOrder })
            if !sorted.isEmpty {
                return sorted.enumerated().map { index, subcategory in
                    ChapterRow(
                        id: subcategory.id,
                        title: subcategory.title,
                        icon: ChapterRow.icons[index % ChapterRow.icons.count]
                    )
                }
            }
        }
        return ChapterRow.defaults
    }

    private var selectedSubcategory: CSSubcategory? {
        guard let content = selectedCategoryContent else { return nil }

        if let matched = content.subcategories.first(where: { $0.id == subcategoryID }) {
            return matched
        }

        return content.subcategories.first {
            normalized($0.title) == normalized(subcategoryID)
        }
    }

    private var lessonTitle: String {
        if let selectedSubcategory {
            return selectedSubcategory.title
        }

        if let chapterRow = chapterRows.first(where: { $0.id == subcategoryID }) {
            return chapterRow.title
        }

        return "Lesson"
    }

    private var lessonNumber: Int {
        if let index = chapterRows.firstIndex(where: { $0.id == subcategoryID }) {
            return index + 1
        }

        if let index = chapterRows.firstIndex(where: { normalized($0.title) == normalized(lessonTitle) }) {
            return index + 1
        }

        return 1
    }

    private var lessonNumberText: String {
        lessonNumber < 10 ? "0\(lessonNumber)" : "\(lessonNumber)"
    }

    private var lessonBadgeText: String {
        guard let categoryTitle = store.categories.first(where: { $0.id == categoryID })?.title else {
            return "LESSON"
        }
        return categoryTitle.uppercased()
    }

    private var selectedStudyItem: CSStudyItem? {
        selectedSubcategory?.items.sorted(by: { $0.displayOrder < $1.displayOrder }).first
    }

    private var definitionHeadline: String {
        selectedStudyItem?.summary ?? ""
    }

    private var definitionBody: String {
        guard
            let body = selectedStudyItem?.body
                .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                .filter({ !$0.isEmpty }),
            !body.isEmpty
        else {
            return ""
        }
        return body.joined(separator: " ")
    }

    private var characteristics: [LessonCharacteristic] {
        guard
            let keyPoints = selectedStudyItem?.keyPoints
                .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                .filter({ !$0.isEmpty }),
            !keyPoints.isEmpty
        else {
            return []
        }

        return keyPoints.enumerated().map { index, point in
            let number = index + 1 < 10 ? "0\(index + 1)" : "\(index + 1)"
            let title = "POINT \(number)"
            return LessonCharacteristic(title: title, description: point)
        }
    }

    private var keywordTags: [String] {
        selectedStudyItem?.keywords
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ !$0.isEmpty }) ?? []
    }

    private var interviewPrompts: [String] {
        selectedStudyItem?.interviewPrompts
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ !$0.isEmpty }) ?? []
    }

    private var checkQuestions: [String] {
        selectedStudyItem?.checkQuestions
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ !$0.isEmpty }) ?? []
    }

    private var nextLessonRow: ChapterRow? {
        guard let currentIndex = chapterRows.firstIndex(where: { $0.id == subcategoryID }) else {
            if let fallbackIndex = chapterRows.firstIndex(where: { normalized($0.title) == normalized(lessonTitle) }),
               fallbackIndex + 1 < chapterRows.count {
                return chapterRows[fallbackIndex + 1]
            }
            return nil
        }

        let nextIndex = currentIndex + 1
        guard nextIndex < chapterRows.count else { return nil }
        return chapterRows[nextIndex]
    }

    private func normalized(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
    }
}

private struct LessonCharacteristic: Identifiable {
    let id: String
    let title: String
    let description: String

    init(title: String, description: String) {
        self.id = title
        self.title = title
        self.description = description
    }
}

private struct ChapterRow: Identifiable {
    let id: String
    let title: String
    let icon: String

    static let icons: [String] = [
        "tablecells",
        "link",
        "square.stack.3d.up",
        "line.3.horizontal",
        "point.3.connected.trianglepath.dotted",
        "point.3.filled.connected.trianglepath.dotted",
        "square.grid.2x2"
    ]

    static let defaults: [ChapterRow] = [
        ChapterRow(id: "arrays", title: "Arrays", icon: "tablecells"),
        ChapterRow(id: "linked-lists", title: "Linked Lists", icon: "link"),
        ChapterRow(id: "stacks", title: "Stacks", icon: "square.stack.3d.up"),
        ChapterRow(id: "queues", title: "Queues", icon: "line.3.horizontal"),
        ChapterRow(id: "trees", title: "Trees", icon: "point.3.connected.trianglepath.dotted"),
        ChapterRow(id: "graphs", title: "Graphs", icon: "point.3.filled.connected.trianglepath.dotted"),
        ChapterRow(id: "hash-tables", title: "Hash Tables", icon: "square.grid.2x2")
    ]
}

private struct CurriculumCard: Identifiable {
    struct Style {
        let icon: String
        let iconBackground: Color
        let iconColor: Color
        let defaultDescription: String
        let defaultTags: [String]
    }

    let id: String
    let categoryID: String?
    let title: String
    let description: String
    let tags: [String]
    let icon: String
    let iconBackground: Color
    let iconColor: Color

    static let styles: [Style] = [
        Style(
            icon: "square.grid.3x3",
            iconBackground: Color(red: 0.94, green: 0.97, blue: 1.0),
            iconColor: Color(red: 0.17, green: 0.39, blue: 0.92),
            defaultDescription: "Master the organization and storage of data for efficient access and modification.",
            defaultTags: ["ARRAYS", "GRAPHS", "+12 MORE"]
        ),
        Style(
            icon: "sum",
            iconBackground: Color(red: 1.0, green: 0.98, blue: 0.92),
            iconColor: Color(red: 0.88, green: 0.52, blue: 0.0),
            defaultDescription: "Learn step-by-step procedures for calculations, data processing, and automated reasoning.",
            defaultTags: ["SORTING", "DYNAMIC PROGRAMMING"]
        ),
        Style(
            icon: "terminal",
            iconBackground: Color(red: 0.98, green: 0.96, blue: 1.0),
            iconColor: Color(red: 0.58, green: 0.26, blue: 0.91),
            defaultDescription: "Understand kernel architecture, process management, and memory allocation.",
            defaultTags: []
        ),
        Style(
            icon: "cylinder",
            iconBackground: Color(red: 0.93, green: 0.99, blue: 0.96),
            iconColor: Color(red: 0.05, green: 0.62, blue: 0.43),
            defaultDescription: "Design relational schemas, optimize SQL queries, and explore NoSQL solutions.",
            defaultTags: []
        ),
        Style(
            icon: "point.3.filled.connected.trianglepath.dotted",
            iconBackground: Color(red: 1.0, green: 0.95, blue: 0.96),
            iconColor: Color(red: 0.93, green: 0.13, blue: 0.36),
            defaultDescription: "Explore the OSI model, TCP/IP, and the protocols that power the internet.",
            defaultTags: []
        )
    ]

    static let defaults: [CurriculumCard] = [
        CurriculumCard(
            id: "data-structures",
            categoryID: nil,
            title: "Data Structures",
            description: styles[0].defaultDescription,
            tags: styles[0].defaultTags,
            icon: styles[0].icon,
            iconBackground: styles[0].iconBackground,
            iconColor: styles[0].iconColor
        ),
        CurriculumCard(
            id: "algorithms",
            categoryID: nil,
            title: "Algorithms",
            description: styles[1].defaultDescription,
            tags: styles[1].defaultTags,
            icon: styles[1].icon,
            iconBackground: styles[1].iconBackground,
            iconColor: styles[1].iconColor
        ),
        CurriculumCard(
            id: "operating-systems",
            categoryID: nil,
            title: "Operating Systems",
            description: styles[2].defaultDescription,
            tags: [],
            icon: styles[2].icon,
            iconBackground: styles[2].iconBackground,
            iconColor: styles[2].iconColor
        ),
        CurriculumCard(
            id: "databases",
            categoryID: nil,
            title: "Databases",
            description: styles[3].defaultDescription,
            tags: [],
            icon: styles[3].icon,
            iconBackground: styles[3].iconBackground,
            iconColor: styles[3].iconColor
        ),
        CurriculumCard(
            id: "networking",
            categoryID: nil,
            title: "Networking",
            description: styles[4].defaultDescription,
            tags: [],
            icon: styles[4].icon,
            iconBackground: styles[4].iconBackground,
            iconColor: styles[4].iconColor
        )
    ]
}
#else
import SwiftUI
import ComposableArchitecture

struct HomeIOSCoordinator: View {
    let store: StoreOf<HomeFeature>

    var body: some View {
        EmptyView()
    }
}

struct HomeIOSContainer: View {
    let store: StoreOf<HomeFeature>

    var body: some View {
        EmptyView()
    }
}
#endif
