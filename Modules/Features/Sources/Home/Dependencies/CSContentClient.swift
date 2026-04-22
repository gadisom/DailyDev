import ComposableArchitecture
import Data
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

        return CSContentClient(
            fetchCategories: {
                try await repository.fetchCategories()
                    .sorted { $0.displayOrder < $1.displayOrder }
            },
            fetchCategoryContent: { categorySlug in
                try await repository.fetchCategoryContent(categorySlug: categorySlug)
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
