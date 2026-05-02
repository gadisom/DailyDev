import Entity
import Foundation

public struct FetchPostBlogSourcesUseCase: Sendable {
    private let repository: any PostArticleRepository

    public init(repository: any PostArticleRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [PostBlogSource] {
        try await repository.fetchBlogSources()
    }
}
