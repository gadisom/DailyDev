public struct QuizCategoryDTO: Decodable, Sendable {
    public let id: String
    public let name: String
    public let englishName: String
    public let icon: String
    public let iconColor: String
    public let iconBgColor: String
}

public struct QuizQuestionDTO: Decodable, Sendable {
    public let id: Int
    public let categoryId: String
    public let type: String
    public let question: String
    public let choices: [String]
    public let correctIndex: Int
    public let oxAnswer: String
    public let fillAnswer: String
    public let explanation: String
    public let concept: String
    public let tag: String
}
