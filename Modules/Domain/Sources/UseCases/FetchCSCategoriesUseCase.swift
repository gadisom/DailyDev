import Entity
import Foundation

public struct FetchCSCategoriesUseCase: Sendable {
    private let repository: any CSContentRepository

    public init(repository: any CSContentRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [CSCategoryDefinition] {
        try await repository.fetchCategories()
    }
}
