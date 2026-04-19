import ComposableArchitecture
import Data
import Domain
import Entity
import Foundation

public struct CSContentClient: Sendable {
    public var fetchManifest: @Sendable () async throws -> CSContentManifest
    public var fetchCategories: @Sendable () async throws -> [CSCategoryDefinition]
    public var fetchCategoryContent: @Sendable (_ prodFile: String) async throws -> CSCategoryContent

public init(
        fetchManifest: @escaping @Sendable () async throws -> CSContentManifest,
        fetchCategories: @escaping @Sendable () async throws -> [CSCategoryDefinition],
        fetchCategoryContent: @escaping @Sendable (_ prodFile: String) async throws -> CSCategoryContent
    ) {
        self.fetchManifest = fetchManifest
        self.fetchCategories = fetchCategories
        self.fetchCategoryContent = fetchCategoryContent
    }
}

private enum CSContentClientKey: DependencyKey {
    static let liveValue: CSContentClient = {
        let repository = CSContentRepository()
        let syncUseCase = SyncCSContentUseCase(repository: repository)
        let fetchManifestUseCase = FetchCSManifestUseCase(repository: repository)
        let fetchCategoriesUseCase = FetchCSCategoriesUseCase(repository: repository)
        let fetchCategoryContentUseCase = FetchCSCategoryContentUseCase(repository: repository)

        return CSContentClient(
            fetchManifest: {
                try await syncUseCase.execute()
                return try await fetchManifestUseCase.execute()
            },
            fetchCategories: {
                do {
                    return try await fetchCategoriesUseCase.execute()
                        .sorted { $0.displayOrder < $1.displayOrder }
                } catch {
                    _ = try? await syncUseCase.execute(forceRefresh: true)
                    return try await fetchCategoriesUseCase.execute()
                        .sorted { $0.displayOrder < $1.displayOrder }
                }
            },
            fetchCategoryContent: { prodFile in
                do {
                    return try await fetchCategoryContentUseCase.execute(prodFile: prodFile)
                } catch {
                    _ = try? await syncUseCase.execute(forceRefresh: true)
                    return try await fetchCategoryContentUseCase.execute(prodFile: prodFile)
                }
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
