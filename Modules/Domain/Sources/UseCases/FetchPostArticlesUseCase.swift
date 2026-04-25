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
