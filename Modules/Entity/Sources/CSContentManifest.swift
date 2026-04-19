import Foundation

public struct CSContentManifest: Codable, Equatable, Sendable {
    public let version: Int
    public let updatedAt: String
    public let files: [String]

    public init(version: Int, updatedAt: String, files: [String]) {
        self.version = version
        self.updatedAt = updatedAt
        self.files = files
    }
}
