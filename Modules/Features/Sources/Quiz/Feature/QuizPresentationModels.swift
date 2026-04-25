#if os(iOS)
import DesignSystem
import Entity
import SwiftUI

struct QuizCategoryUIModel: Identifiable {
    let id: String
    let name: String
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let questions: [QuizQuestion]

    init(
        id: String,
        name: String,
        icon: String,
        iconColor: Color,
        iconBackground: Color,
        questions: [QuizQuestion]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.iconColor = iconColor
        self.iconBackground = iconBackground
        self.questions = questions
    }

    init(_ category: QuizCategory) {
        self.init(
            id: category.id,
            name: category.name,
            icon: category.icon,
            iconColor: Color(hexString: category.iconColorHex),
            iconBackground: Color(hexString: category.iconBackgroundHex),
            questions: category.questions
        )
    }

    var questionsByType: [(label: String, tag: String, items: [QuizQuestion])] {
        let mcq = questions.filter { $0.type == .mcq }
        let ox = questions.filter { $0.type == .ox }
        let fill = questions.filter { $0.type == .fill }
        var out: [(String, String, [QuizQuestion])] = []
        if !mcq.isEmpty { out.append(("객관식", "Multiple Choice", mcq)) }
        if !ox.isEmpty { out.append(("OX", "True / False", ox)) }
        if !fill.isEmpty { out.append(("빈칸", "Fill in Blank", fill)) }
        return out
    }

    func toQuizSet() -> QuizSet {
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
