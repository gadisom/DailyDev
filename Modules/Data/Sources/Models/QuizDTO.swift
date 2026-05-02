import Foundation

struct QuizCategoryDTO: Decodable, Sendable {
    let id: String
    let name: String
    let icon: String
    let iconColor: String
    let iconBgColor: String
}

struct QuizQuestionDTO: Decodable, Sendable {
    let id: Int
    let categoryId: String
    let type: String
    let question: String
    let choices: [String]
    let correctIndex: String  // "0" | "1,2" 형태로 DB에서 전달
    let oxAnswer: String
    let fillAnswer: String
    let explanation: String
    let concept: String
    let tag: String

    enum CodingKeys: String, CodingKey {
        case id
        case categoryId
        case type
        case question
        case choices
        case correctIndex
        case oxAnswer
        case fillAnswer
        case explanation
        case concept
        case tag
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.categoryId = try container.decode(String.self, forKey: .categoryId)
        self.type = try container.decode(String.self, forKey: .type)
        self.question = try container.decode(String.self, forKey: .question)
        self.choices = try container.decode([String].self, forKey: .choices)
        self.oxAnswer = try container.decode(String.self, forKey: .oxAnswer)
        self.fillAnswer = try container.decode(String.self, forKey: .fillAnswer)
        self.explanation = try container.decode(String.self, forKey: .explanation)
        self.concept = try container.decode(String.self, forKey: .concept)
        self.tag = try container.decode(String.self, forKey: .tag)

        if let stringValue = try? container.decode(String.self, forKey: .correctIndex) {
            self.correctIndex = stringValue
        } else {
            let intValue = try container.decode(Int.self, forKey: .correctIndex)
            self.correctIndex = String(intValue)
        }
    }

    var parsedCorrectIndices: [Int] {
        correctIndex
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }
}
