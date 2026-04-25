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
    func fetchQuizBank() async throws -> [QuizCategory]
}

public struct FetchQuizBankUseCase: Sendable {
    private let repository: any QuizRepository

    public init(repository: any QuizRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [QuizCategory] {
        try await repository.fetchQuizBank()
    }
}
