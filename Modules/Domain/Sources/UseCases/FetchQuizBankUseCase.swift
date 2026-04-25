import Entity
import Foundation

public struct FetchQuizBankUseCase: Sendable {
    private let repository: any QuizRepository

    public init(repository: any QuizRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [QuizCategory] {
        try await repository.fetchQuizBank()
    }
}
