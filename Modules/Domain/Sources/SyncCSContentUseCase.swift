import Foundation
import Entity

public struct SyncCSContentUseCase: Sendable {
    private let repository: any CSResourceRepository

    public init(repository: any CSResourceRepository) {
        self.repository = repository
    }

    public func execute(forceRefresh: Bool = false) async throws -> CSContentManifest {
        try await repository.syncIfNeeded(forceRefresh: forceRefresh)
    }
}
