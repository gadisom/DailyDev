import Foundation

public struct PostArticlesPage: Equatable, Sendable {
    public let items: [PostArticleListItem]
    public let hasNext: Bool
    public let nextCursor: Int64?

    public init(items: [PostArticleListItem], hasNext: Bool, nextCursor: Int64?) {
        self.items = items
        self.hasNext = hasNext
        self.nextCursor = nextCursor
    }
}
