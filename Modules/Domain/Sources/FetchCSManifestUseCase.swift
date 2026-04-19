import Foundation
import Entity

public struct FetchCSManifestUseCase: Sendable {
    private let repository: any CSResourceRepository

    public init(repository: any CSResourceRepository) {
        self.repository = repository
    }

    public func execute() async throws -> CSContentManifest {
        try await repository.fetchManifest()
    }
}
