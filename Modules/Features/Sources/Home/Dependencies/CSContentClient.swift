import ComposableArchitecture
import Data
import Domain
import Entity
import Foundation

public struct CSContentClient: Sendable {
    public var fetchCategories: @Sendable () async throws -> [CSCategoryDefinition]
    public var fetchCategoryContent: @Sendable (_ categorySlug: String) async throws -> CSCategoryContent

    public init(
        fetchCategories: @escaping @Sendable () async throws -> [CSCategoryDefinition],
        fetchCategoryContent: @escaping @Sendable (_ categorySlug: String) async throws -> CSCategoryContent
    ) {
        self.fetchCategories = fetchCategories
        self.fetchCategoryContent = fetchCategoryContent
    }
}

private enum CSContentClientKey: DependencyKey {
    static let liveValue: CSContentClient = {
        let repository = CSSupabaseContentRepository()
        let fetchCategoriesUseCase = FetchCSCategoriesUseCase(repository: repository)
        let fetchCategoryContentUseCase = FetchCSCategoryContentUseCase(repository: repository)

        return CSContentClient(
            fetchCategories: {
                try await fetchCategoriesUseCase.execute()
                    .sorted { $0.displayOrder < $1.displayOrder }
            },
            fetchCategoryContent: { categorySlug in
                try await fetchCategoryContentUseCase.execute(categorySlug: categorySlug)
            }
        )
    }()
}

extension DependencyValues {
    var csContentClient: CSContentClient {
        get { self[CSContentClientKey.self] }
        set { self[CSContentClientKey.self] = newValue }
    }
}
