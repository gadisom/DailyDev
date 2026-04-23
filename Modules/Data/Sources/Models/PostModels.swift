struct PostArticlesAPIEnvelopeDTO: Decodable {
    let resultType: String
    let data: PostArticlesPayloadDTO?
    let errorMessage: PostAPIErrorPayloadDTO?
}

struct PostArticlesPayloadDTO: Decodable {
    let data: [PostArticleEntryDTO]
    let hasNext: Bool
    let nextCursor: Int64?
}

struct PostArticleEntryDTO: Decodable {
    let article: PostAPIDomainArticleDTO
    let blog: PostAPIDomainBlogDTO
}

struct PostAPIDomainArticleDTO: Decodable {
    let id: Int64
    let blogId: Int64
    let title: String
    let link: String
    let guid: String?
    let pubDate: Int64
    let views: Int
}

struct PostAPIDomainBlogDTO: Decodable {
    let id: Int64
    let link: String
    let name: String
    let logoUrl: String?
    let rssLink: String?
}

struct PostAPIErrorPayloadDTO: Decodable {
    let code: String?
    let message: String?
}
