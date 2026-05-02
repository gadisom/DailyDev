import Foundation

public struct PostArticle: Identifiable, Equatable, Hashable, Sendable {
    public let id: Int64
    public let blogID: Int64
    public let title: String
    public let link: String
    public let guid: String?
    public let publishedAtMillis: Int64
    public let views: Int

    public init(
        id: Int64,
        blogID: Int64,
        title: String,
        link: String,
        guid: String?,
        publishedAtMillis: Int64,
        views: Int
    ) {
        self.id = id
        self.blogID = blogID
        self.title = title
        self.link = link
        self.guid = guid
        self.publishedAtMillis = publishedAtMillis
        self.views = views
    }
}
