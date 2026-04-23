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
        let englishName: String
        let sortOrder: Int
    }

    let id: String
    let categoryID: String?
    let title: String
    let englishName: String
    let tags: [String]
    let icon: String
    let iconBackground: Color
    let iconColor: Color

    // Slug-based mapping: identical icons/colors to the quiz tab
    private static let slugStyleMap: [(keywords: [String], style: Style)] = [
        (
            ["datastructure", "data-struct", "자료구조"],
            Style(
                icon: "square.grid.3x3",
                iconBackground: BrandPalette.curriculumBlueBackground,
                iconColor: BrandPalette.curriculumBlueText,
                englishName: "Data Structures",
                sortOrder: 1
            )
        ),
        (
            ["algo", "알고리즘"],
            Style(
                icon: "sum",
                iconBackground: BrandPalette.curriculumOrangeBackground,
                iconColor: BrandPalette.curriculumOrangeText,
                englishName: "Algorithms",
                sortOrder: 2
            )
        ),
        (
            ["operating", "운영체제"],
            Style(
                icon: "terminal",
                iconBackground: BrandPalette.curriculumPurpleBackground,
                iconColor: BrandPalette.curriculumPurpleText,
                englishName: "Operating System",
                sortOrder: 3
            )
        ),
        (
            ["database", "데이터베이스"],
            Style(
                icon: "cylinder",
                iconBackground: BrandPalette.curriculumGreenBackground,
                iconColor: BrandPalette.curriculumGreenText,
                englishName: "Database",
                sortOrder: 4
            )
        ),
        (
            ["network", "네트워크"],
            Style(
                icon: "point.3.filled.connected.trianglepath.dotted",
                iconBackground: BrandPalette.curriculumRedBackground,
                iconColor: BrandPalette.curriculumRedText,
                englishName: "Network",
                sortOrder: 5
            )
        ),
    ]

    // Fallback cycle (for slugs that don't match any keyword)
    static let styles: [Style] = slugStyleMap.map(\.style)

    static func styleFor(slug: String) -> Style? {
        // Normalize: lowercase + remove separators
        let id = slug
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
        return slugStyleMap.first { entry in
            entry.keywords.contains { id.contains($0) }
        }?.style
    }

    static func sortOrder(for slug: String) -> Int {
        styleFor(slug: slug)?.sortOrder ?? 99
    }
}
#endif
