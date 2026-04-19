import Foundation
import Entity

public struct FetchCSCategoryContentUseCase: Sendable {
    private let repository: any CSResourceRepository

    public init(repository: any CSResourceRepository) {
        self.repository = repository
    }

    public func execute(prodFile: String) async throws -> CSCategoryContent {
        try await repository.fetchCategoryContent(prodFile: prodFile)
    }
}
