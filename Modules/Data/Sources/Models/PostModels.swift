struct PostArticlesAPIEnvelope: Decodable {
    let resultType: String
    let data: PostArticlesPayload?
    let errorMessage: PostAPIErrorPayload?
}

struct PostArticlesPayload: Decodable {
    let data: [PostArticleEntry]
    let hasNext: Bool
    let nextCursor: Int64?
}

struct PostArticleEntry: Decodable {
    let article: PostAPIDomainArticle
    let blog: PostAPIDomainBlog
}

struct PostAPIDomainArticle: Decodable {
    let id: Int64
    let blogId: Int64
    let title: String
    let link: String
    let guid: String?
    let pubDate: Int64
    let views: Int
}

struct PostAPIDomainBlog: Decodable {
    let id: Int64
    let link: String
    let name: String
    let logoUrl: String?
    let rssLink: String?
}

struct PostAPIErrorPayload: Decodable {
    let code: String?
    let message: String?
}
