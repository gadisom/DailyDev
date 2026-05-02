import Foundation

public struct PostArticleListItem: Identifiable, Equatable, Sendable {
    public let id: Int64
    public let title: String
    public let articleLink: String
    public let blogName: String
    public let blogLink: String
    public let publishedAtMillis: Int64

    public init(
        id: Int64,
        title: String,
        articleLink: String,
        blogName: String,
        blogLink: String,
        publishedAtMillis: Int64
    ) {
        self.id = id
        self.title = title
        self.articleLink = articleLink
        self.blogName = blogName
        self.blogLink = blogLink
        self.publishedAtMillis = publishedAtMillis
    }
}
