import ComposableArchitecture
import Foundation

public struct ProfileClient {
    public var fetchProfile: () async throws -> UserProfile
}

public struct UserProfile: Equatable, Sendable {
    public let id: String
    public let name: String
    public let email: String

    public init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}

private enum ProfileClientKey: DependencyKey {
    static let liveValue = ProfileClient(
        fetchProfile: { throw ProfileClientError.notImplemented }
    )
}

extension DependencyValues {
    public var profileClient: ProfileClient {
        get { self[ProfileClientKey.self] }
        set { self[ProfileClientKey.self] = newValue }
    }
}

private enum ProfileClientError: Error {
    case notImplemented
}
