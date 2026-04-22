#if os(iOS)
import SwiftUI

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

struct CurriculumCard: Identifiable {
    struct Style {
        let icon: String
        let iconBackground: Color
        let iconColor: Color
    }

    let id: String
    let categoryID: String?
    let title: String
    let tags: [String]
    let icon: String
    let iconBackground: Color
    let iconColor: Color

    static let styles: [Style] = [
        Style(
            icon: "square.grid.3x3",
            iconBackground: Color(red: 0.94, green: 0.97, blue: 1.0),
            iconColor: Color(red: 0.17, green: 0.39, blue: 0.92)
        ),
        Style(
            icon: "sum",
            iconBackground: Color(red: 1.0, green: 0.98, blue: 0.92),
            iconColor: Color(red: 0.88, green: 0.52, blue: 0.0)
        ),
        Style(
            icon: "terminal",
            iconBackground: Color(red: 0.98, green: 0.96, blue: 1.0),
            iconColor: Color(red: 0.58, green: 0.26, blue: 0.91)
        ),
        Style(
            icon: "cylinder",
            iconBackground: Color(red: 0.93, green: 0.99, blue: 0.96),
            iconColor: Color(red: 0.05, green: 0.62, blue: 0.43)
        ),
        Style(
            icon: "point.3.filled.connected.trianglepath.dotted",
            iconBackground: Color(red: 1.0, green: 0.95, blue: 0.96),
            iconColor: Color(red: 0.93, green: 0.13, blue: 0.36)
        )
    ]

    static let defaults: [CurriculumCard] = [
        CurriculumCard(
            id: "data-structures",
            categoryID: nil,
            title: "Data Structures",
            tags: [],
            icon: styles[0].icon,
            iconBackground: styles[0].iconBackground,
            iconColor: styles[0].iconColor
        ),
        CurriculumCard(
            id: "algorithms",
            categoryID: nil,
            title: "Algorithms",
            tags: [],
            icon: styles[1].icon,
            iconBackground: styles[1].iconBackground,
            iconColor: styles[1].iconColor
        ),
        CurriculumCard(
            id: "operating-systems",
            categoryID: nil,
            title: "Operating Systems",
            tags: [],
            icon: styles[2].icon,
            iconBackground: styles[2].iconBackground,
            iconColor: styles[2].iconColor
        ),
        CurriculumCard(
            id: "databases",
            categoryID: nil,
            title: "Databases",
            tags: [],
            icon: styles[3].icon,
            iconBackground: styles[3].iconBackground,
            iconColor: styles[3].iconColor
        ),
        CurriculumCard(
            id: "networking",
            categoryID: nil,
            title: "Networking",
            tags: [],
            icon: styles[4].icon,
            iconBackground: styles[4].iconBackground,
            iconColor: styles[4].iconColor
        )
    ]
}
#endif
