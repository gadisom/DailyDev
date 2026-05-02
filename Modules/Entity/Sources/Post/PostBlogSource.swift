import Foundation

public struct PostBlogSource: Identifiable, Equatable, Hashable, Sendable {
    public var id: String { name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

    public let order: Int
    public let link: String
    public let name: String

    public init(order: Int, link: String, name: String) {
        self.order = order
        self.link = link
        self.name = name
    }
}
