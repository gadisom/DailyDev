import Foundation

public struct QuizQuestion: Identifiable, Equatable, Sendable {
    public let id: Int
    public let type: QuizQuestionType
    public let question: String
    public let choices: [String]
    public let correctIndices: [Int]  // MCQ 정답 인덱스 목록 ([] = MCQ 아님, 복수 정답 가능)
    public let oxAnswer: String       // "O" | "X" | ""
    public let fillAnswer: String     // 빈칸 정답 | ""
    public let explanation: String
    public let concept: String
    public let tag: String

    public var isMultiSelect: Bool { correctIndices.count > 1 }

    public init(
        id: Int,
        type: QuizQuestionType,
        question: String,
        choices: [String],
        correctIndices: [Int],
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
        self.correctIndices = correctIndices
        self.oxAnswer = oxAnswer
        self.fillAnswer = fillAnswer
        self.explanation = explanation
        self.concept = concept
        self.tag = tag
    }
}
