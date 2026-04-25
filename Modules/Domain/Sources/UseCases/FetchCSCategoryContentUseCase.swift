import Entity
import Foundation

public struct FetchCSCategoryContentUseCase: Sendable {
    private let repository: any CSContentRepository

    public init(repository: any CSContentRepository) {
        self.repository = repository
    }

    public func execute(categorySlug: String) async throws -> CSCategoryContent {
        try await repository.fetchCategoryContent(categorySlug: categorySlug)
    }
}
