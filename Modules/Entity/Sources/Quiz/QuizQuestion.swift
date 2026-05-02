import Foundation

public struct QuizQuestion: Identifiable, Equatable, Sendable {
    public let id: Int
    public let type: QuizQuestionType
    public let question: String
    public let choices: [String]
    public let correctIndex: Int      // MCQ 정답 인덱스 (-1 = MCQ 아님)
    public let oxAnswer: String       // "O" | "X" | ""
    public let fillAnswer: String     // 빈칸 정답 | ""
    public let explanation: String
    public let concept: String
    public let tag: String

    public init(
        id: Int,
        type: QuizQuestionType,
        question: String,
        choices: [String],
        correctIndex: Int,
        oxAnswer: String,
        fillAnswer: String,
        explanation: String,
        concept: String,
        tag: String
    ) {
        self.id = id
        self.type = type
        self.question = question
        self.choices = choices
        self.correctIndex = correctIndex
        self.oxAnswer = oxAnswer
        self.fillAnswer = fillAnswer
        self.explanation = explanation
        self.concept = concept
        self.tag = tag
    }
}
