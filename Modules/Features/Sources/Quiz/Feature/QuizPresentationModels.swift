#if os(iOS)
import DesignSystem
import Entity
import SwiftUI

public struct QuizCategoryUIModel: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let icon: String
    public let iconColor: Color
    public let iconBackground: Color
    public let sortOrder: Int
    public let questions: [QuizQuestion]

    public init(
        id: String,
        name: String,
        icon: String,
        iconColor: Color,
        iconBackground: Color,
        sortOrder: Int = Int.max,
        questions: [QuizQuestion]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.iconColor = iconColor
        self.iconBackground = iconBackground
        self.sortOrder = sortOrder
        self.questions = questions
    }

    public init(_ category: QuizCategory) {
        let style = LearningCategoryVisualStyle.style(for: category.id, title: category.name)
        self.init(
            id: category.id,
            name: category.name,
            icon: style?.icon ?? category.icon,
            iconColor: style?.iconColor ?? Color(hexString: category.iconColorHex),
            iconBackground: style?.iconBackground ?? Color(hexString: category.iconBackgroundHex),
            sortOrder: style?.sortOrder ?? Int.max,
            questions: category.questions
        )
    }

    public var questionsByType: [(label: String, tag: String, items: [QuizQuestion])] {
        let mcq = questions.filter { $0.type == .mcq }
        let ox = questions.filter { $0.type == .ox }
        let fill = questions.filter { $0.type == .fill }
        var out: [(String, String, [QuizQuestion])] = []
        if !mcq.isEmpty { out.append(("객관식", "Multiple Choice", mcq)) }
        if !ox.isEmpty { out.append(("OX", "True / False", ox)) }
        if !fill.isEmpty { out.append(("빈칸", "Fill in Blank", fill)) }
        return out
    }

    public func toQuizSet() -> QuizSet {
        QuizSet(
            chapter: name,
            chapterNum: "—",
            discipline: name,
            questions: questions,
            passingScore: 80
        )
    }
}
#endif
