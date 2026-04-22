#if os(iOS)
import Foundation
import Entity

struct HomeTopicPresentation {
    let titleForHero: String
    let summaryText: String
    let chapterRows: [ChapterRow]
    let pagesCountText: String
    let diagramCountText: String
    let algorithmCountText: String
    let isCategoryLoading: Bool
    let categoryErrorMessage: String?
}

struct HomeLessonPresentation {
    let lessonTitle: String
    let lessonNumberText: String
    let lessonBadgeText: String
    let illustrationURLs: [URL]
    let contentBlocks: [LessonContentBlock]
    let definitionHeadline: String
    let definitionBody: String
    let characteristics: [LessonCharacteristic]
    let keywordTags: [String]
    let interviewPrompts: [String]
    let checkQuestions: [String]
    let nextLessonRow: ChapterRow?
}

enum HomeIOSPresentationBuilder {
    static func displayCards(
        categories: [CSCategoryDefinition],
        selectedCategoryID: String?,
        selectedContent: CSCategoryContent?
    ) -> [CurriculumCard] {
        let sortedCategories = categories.sorted { $0.displayOrder < $1.displayOrder }

        guard !sortedCategories.isEmpty else {
            return CurriculumCard.defaults
        }

        return sortedCategories.enumerated().map { index, category in
            let style = CurriculumCard.styles[index % CurriculumCard.styles.count]

            return CurriculumCard(
                id: category.id,
                categoryID: category.id,
                title: category.title,
                tags: cardTags(
                    categoryID: category.id,
                    selectedCategoryID: selectedCategoryID,
                    selectedContent: selectedContent
                ),
                icon: style.icon,
                iconBackground: style.iconBackground,
                iconColor: style.iconColor
            )
        }
    }

    static func topic(
        categoryID: String,
        categories: [CSCategoryDefinition],
        selectedCategoryID: String?,
        selectedContent: CSCategoryContent?,
        isLoading: Bool,
        errorMessage: String?
    ) -> HomeTopicPresentation {
        let categoryTitle = categories.first(where: { $0.id == categoryID })?.title ?? "Data Structures"
        let content = selectedCategoryID == categoryID ? selectedContent : nil
        let chapterRows = chapterRows(from: content)

        let summaryText = topicSummaryText(from: content)
        let pagesCount = pagesCountText(from: content)
        let diagramCount = content.map { "\($0.subcategories.count)" } ?? "24"
        let algorithmCount = content.map {
            "\($0.subcategories.reduce(0) { $0 + $1.items.count })"
        } ?? "12"

        return HomeTopicPresentation(
            titleForHero: splitTitle(categoryTitle),
            summaryText: summaryText,
            chapterRows: chapterRows,
            pagesCountText: pagesCount,
            diagramCountText: diagramCount,
            algorithmCountText: algorithmCount,
            isCategoryLoading: isLoading && selectedCategoryID == categoryID,
            categoryErrorMessage: selectedCategoryID == categoryID ? errorMessage : nil
        )
    }

    static func lesson(
        categoryID: String,
        subcategoryID: String,
        categories: [CSCategoryDefinition],
        selectedCategoryID: String?,
        selectedContent: CSCategoryContent?
    ) -> HomeLessonPresentation {
        let content = selectedCategoryID == categoryID ? selectedContent : nil
        let chapterRows = chapterRows(from: content)
        let selectedSubcategory = selectedSubcategory(from: content, subcategoryID: subcategoryID)

        let lessonTitle: String = {
            if let selectedSubcategory {
                return selectedSubcategory.title
            }
            if let chapterRow = chapterRows.first(where: { $0.id == subcategoryID }) {
                return chapterRow.title
            }
            return "Lesson"
        }()

        let lessonNumber: Int = {
            if let index = chapterRows.firstIndex(where: { $0.id == subcategoryID }) {
                return index + 1
            }
            if let index = chapterRows.firstIndex(where: { normalized($0.title) == normalized(lessonTitle) }) {
                return index + 1
            }
            return 1
        }()

        let lessonBadgeText = categories
            .first(where: { $0.id == categoryID })?
            .title
            .uppercased() ?? "LESSON"

        let selectedStudyItem = selectedSubcategory?.items
            .sorted(by: { $0.displayOrder < $1.displayOrder })
            .first

        let illustrationURLs: [URL] = {
            var rawURLs: [String] = selectedStudyItem?.imageUrls ?? []
            if let fallback = selectedStudyItem?.imageUrl, !fallback.isEmpty {
                rawURLs.append(fallback)
            }

            var resolved: [URL] = []
            for raw in rawURLs {
                guard let url = normalizedImageURL(from: raw) else { continue }
                if !resolved.contains(url) {
                    resolved.append(url)
                }
            }
            return resolved
        }()

        let definitionHeadline = selectedStudyItem?.summary ?? ""

        let definitionBody = selectedStudyItem?.body
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ !$0.isEmpty })
            .joined(separator: " ") ?? ""

        let characteristics: [LessonCharacteristic] = {
            let points = selectedStudyItem?.keyPoints
                .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                .filter({ !$0.isEmpty }) ?? []

            return points.enumerated().map { index, point in
                let number = index + 1 < 10 ? "0\(index + 1)" : "\(index + 1)"
                return LessonCharacteristic(title: "POINT \(number)", description: point)
            }
        }()

        let keywordTags = selectedStudyItem?.keywords
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ !$0.isEmpty }) ?? []

        let interviewPrompts = selectedStudyItem?.interviewPrompts
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ !$0.isEmpty }) ?? []

        let checkQuestions = selectedStudyItem?.checkQuestions
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ !$0.isEmpty }) ?? []

        let nextLessonRow: ChapterRow? = {
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
        }()

        let contentBlocks: [LessonContentBlock] = {
            guard let selectedStudyItem else { return [] }

            let ordered = selectedStudyItem.orderedBlocks ?? []
            return ordered.enumerated().compactMap { index, block in
                let kind = lessonContentBlockKind(from: block.type)
                switch kind {
                case .image:
                    let urls = block.items.compactMap { normalizedImageURL(from: $0) }
                    guard !urls.isEmpty else { return nil }
                    return LessonContentBlock(
                        id: "lesson-block-\(index)-image",
                        kind: .image,
                        items: [],
                        imageURLs: urls
                    )
                default:
                    let items = block.items
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    guard !items.isEmpty else { return nil }
                    return LessonContentBlock(
                        id: "lesson-block-\(index)-\(block.type)",
                        kind: kind,
                        items: items,
                        imageURLs: []
                    )
                }
            }
        }()

        return HomeLessonPresentation(
            lessonTitle: lessonTitle,
            lessonNumberText: lessonNumber < 10 ? "0\(lessonNumber)" : "\(lessonNumber)",
            lessonBadgeText: lessonBadgeText,
            illustrationURLs: illustrationURLs,
            contentBlocks: contentBlocks,
            definitionHeadline: definitionHeadline,
            definitionBody: definitionBody,
            characteristics: characteristics,
            keywordTags: keywordTags,
            interviewPrompts: interviewPrompts,
            checkQuestions: checkQuestions,
            nextLessonRow: nextLessonRow
        )
    }

    private static func normalizedImageURL(from raw: String) -> URL? {
        if let url = URL(string: raw), url.scheme != nil {
            return url
        }

        if let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
           let url = URL(string: encoded),
           url.scheme != nil {
            return url
        }

        return nil
    }

    private static func lessonContentBlockKind(from type: String) -> LessonContentBlockKind {
        let normalized = type
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if normalized.contains("image") { return .image }
        if normalized.contains("definition") { return .definition }
        if normalized.contains("key") || normalized.contains("point") { return .keyPoints }
        if normalized.contains("interview") { return .interviewPrompts }
        if normalized.contains("check") || normalized.contains("question") || normalized.contains("quiz") {
            return .checkQuestions
        }
        return .other
    }

    private static func cardTags(
        categoryID: String,
        selectedCategoryID: String?,
        selectedContent: CSCategoryContent?
    ) -> [String] {
        guard
            selectedCategoryID == categoryID,
            let content = selectedContent
        else {
            return []
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

        guard !prefix.isEmpty else { return [] }
        if unique.count > 2 {
            return prefix + ["+\(unique.count - 2) MORE"]
        }
        return prefix
    }

    private static func topicSummaryText(from content: CSCategoryContent?) -> String {
        guard
            let content,
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

    private static func pagesCountText(from content: CSCategoryContent?) -> String {
        guard let content else { return "142" }

        let pages = content.subcategories.reduce(0) { result, subcategory in
            result + max(subcategory.items.count * 2, 1)
        }
        return "\(max(pages, 1))"
    }

    private static func chapterRows(from content: CSCategoryContent?) -> [ChapterRow] {
        guard let content else { return ChapterRow.defaults }

        let sorted = content.subcategories.sorted(by: { $0.displayOrder < $1.displayOrder })
        guard !sorted.isEmpty else { return ChapterRow.defaults }

        return sorted.enumerated().map { index, subcategory in
            ChapterRow(
                id: subcategory.id,
                title: subcategory.title,
                icon: ChapterRow.icons[index % ChapterRow.icons.count]
            )
        }
    }

    private static func selectedSubcategory(
        from content: CSCategoryContent?,
        subcategoryID: String
    ) -> CSSubcategory? {
        guard let content else { return nil }

        if let matched = content.subcategories.first(where: { $0.id == subcategoryID }) {
            return matched
        }

        return content.subcategories.first {
            normalized($0.title) == normalized(subcategoryID)
        }
    }

    private static func splitTitle(_ title: String) -> String {
        let words = title.split(separator: " ")
        guard words.count > 1 else { return title }

        let midpoint = (words.count + 1) / 2
        let firstLine = words.prefix(midpoint).joined(separator: " ")
        let secondLine = words.suffix(words.count - midpoint).joined(separator: " ")
        return "\(firstLine)\n\(secondLine)"
    }

    private static func normalized(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
    }
}
#endif
