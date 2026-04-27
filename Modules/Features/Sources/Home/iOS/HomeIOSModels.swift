#if os(iOS)
import SwiftUI
import DesignSystem

struct LessonCharacteristic: Identifiable {
    let id: String
    let title: String
    let description: String

    init(title: String, description: String) {
        self.id = title
        self.title = title
        self.description = description
    }
}

enum LessonContentBlockKind: Sendable {
    case definition
    case keyPoints
    case interviewPrompts
    case checkQuestions
    case image
    case other
}

struct LessonContentBlock: Identifiable, Sendable {
    let id: String
    let kind: LessonContentBlockKind
    let items: [String]
    let imageURLs: [URL]
}

struct ChapterRow: Identifiable {
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
}

struct CurriculumCard: Identifiable {
    struct Style {
        let icon: String
        let iconBackground: Color
        let iconColor: Color
        let sortOrder: Int
    }

    let id: String
    let categoryID: String?
    let title: String
    let tags: [String]
    let icon: String
    let iconBackground: Color
    let iconColor: Color

    // Slug-based mapping: identical icons/colors to the quiz tab
    private static func style(from style: LearningCategoryVisualStyle) -> Style {
        Style(
            icon: style.icon,
            iconBackground: style.iconBackground,
            iconColor: style.iconColor,
            sortOrder: style.sortOrder
        )
    }

    // Fallback cycle (for slugs that don't match any keyword)
    static let styles: [Style] = LearningCategoryVisualStyle.all.map { style(from: $0) }

    static func styleFor(id: String, title: String? = nil) -> Style? {
        LearningCategoryVisualStyle
            .style(for: id, title: title)
            .map(style(from:))
    }

    static func sortOrder(for id: String, title: String? = nil) -> Int {
        styleFor(id: id, title: title)?.sortOrder ?? 99
    }
}
#endif
