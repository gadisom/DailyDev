import Entity
import Foundation

public protocol QuizRepository: Sendable {
    func fetchQuizBank() async throws -> [QuizCategory]
}
