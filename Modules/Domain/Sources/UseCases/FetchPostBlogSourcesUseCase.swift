import Entity
import Foundation

public struct FetchPostBlogSourcesUseCase: Sendable {
    private let repository: any PostResourceRepository

    public init(repository: any PostResourceRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [PostBlogSource] {
        try await repository.fetchBlogSources()
    }
}
