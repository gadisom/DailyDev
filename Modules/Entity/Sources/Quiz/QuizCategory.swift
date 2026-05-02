import Foundation

public struct QuizCategory: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let icon: String
    public let iconColorHex: String
    public let iconBackgroundHex: String
    public let questions: [QuizQuestion]

    public init(
        id: String,
        name: String,
        icon: String,
        iconColorHex: String,
        iconBackgroundHex: String,
        questions: [QuizQuestion]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.iconColorHex = iconColorHex
        self.iconBackgroundHex = iconBackgroundHex
        self.questions = questions
    }

    public var questionsByType: [(label: String, tag: String, items: [QuizQuestion])] {
        let mcq  = questions.filter { $0.type == .mcq }
        let ox   = questions.filter { $0.type == .ox }
        let fill = questions.filter { $0.type == .fill }
        var out: [(String, String, [QuizQuestion])] = []
        if !mcq.isEmpty  { out.append(("객관식", "Multiple Choice", mcq)) }
        if !ox.isEmpty   { out.append(("OX", "True / False", ox)) }
        if !fill.isEmpty { out.append(("빈칸", "Fill in Blank", fill)) }
        return out
    }

    public func toQuizSet() -> QuizSet {
        QuizSet(chapter: name, chapterNum: "—", discipline: name,
                questions: questions, passingScore: 80)
    }
}
