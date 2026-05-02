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

    var parsedCorrectIndices: [Int] {
        correctIndex
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }
}
