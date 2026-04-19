import Foundation
import Entity

public struct FetchCSCategoriesUseCase: Sendable {
    private let repository: any CSResourceRepository

    public init(repository: any CSResourceRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [CSCategoryDefinition] {
        try await repository.fetchCategories()
    }
}
