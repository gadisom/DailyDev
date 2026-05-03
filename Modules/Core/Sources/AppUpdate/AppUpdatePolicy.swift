import Foundation

public struct AppUpdatePolicy: Sendable, Equatable {
    public let minimumVersion: String
    public let currentVersion: String
    public let updateURL: URL?
    public let message: String

    public init(
        minimumVersion: String,
        currentVersion: String,
        updateURL: URL?,
        message: String
    ) {
        self.minimumVersion = minimumVersion
        self.currentVersion = currentVersion
        self.updateURL = updateURL
        self.message = message
    }
}
