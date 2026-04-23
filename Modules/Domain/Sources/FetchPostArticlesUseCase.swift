import Entity
import Foundation

public struct FetchPostArticlesUseCase: Sendable {
    private let repository: any PostResourceRepository

    public init(repository: any PostResourceRepository) {
        self.repository = repository
    }

    public func execute(cursor: Int64?) async throws -> PostArticlesPage {
        try await repository.fetchArticles(cursor: cursor)
    }
}

// MARK: - Content Service

public protocol CSContentRepository: Sendable {
    func fetchCategories() async throws -> [CSCategoryDefinition]
    func fetchCategoryContent(categorySlug: String) async throws -> CSCategoryContent
}

public struct FetchCSCategoriesUseCase: Sendable {
    private let repository: any CSContentRepository

    public init(repository: any CSContentRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [CSCategoryDefinition] {
        try await repository.fetchCategories()
    }
}

public struct FetchCSCategoryContentUseCase: Sendable {
    private let repository: any CSContentRepository

    public init(repository: any CSContentRepository) {
        self.repository = repository
    }

    public func execute(categorySlug: String) async throws -> CSCategoryContent {
        try await repository.fetchCategoryContent(categorySlug: categorySlug)
    }
}

// MARK: - Quiz Service

public protocol QuizRepository: Sendable {
    func fetchQuizBank() async throws -> (categories: [QuizCategoryDTO], questions: [QuizQuestionDTO])
}

public struct FetchQuizBankUseCase: Sendable {
    private let repository: any QuizRepository

    public init(repository: any QuizRepository) {
        self.repository = repository
    }

    public func execute() async throws -> (categories: [QuizCategoryDTO], questions: [QuizQuestionDTO]) {
        try await repository.fetchQuizBank()
    }
}

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
