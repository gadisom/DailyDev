import Foundation

public struct QuizSet: Equatable, Sendable {
    public let chapter: String
    public let chapterNum: String
    public let discipline: String
    public let questions: [QuizQuestion]
    public let passingScore: Int
    public var allowsEarlyExit: Bool = false

    public init(
        chapter: String,
        chapterNum: String,
        discipline: String,
        questions: [QuizQuestion],
        passingScore: Int,
        allowsEarlyExit: Bool = false
    ) {
        self.chapter = chapter
        self.chapterNum = chapterNum
        self.discipline = discipline
        self.questions = questions
        self.passingScore = passingScore
        self.allowsEarlyExit = allowsEarlyExit
    }
}
