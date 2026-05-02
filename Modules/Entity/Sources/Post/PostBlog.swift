import Foundation

public struct PostBlog: Identifiable, Equatable, Hashable, Sendable {
    public let id: Int64
    public let link: String
    public let name: String

    public init(id: Int64, link: String, name: String) {
        self.id = id
        self.link = link
        self.name = name
    }
}
