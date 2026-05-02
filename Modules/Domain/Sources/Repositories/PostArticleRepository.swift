import Entity
import Foundation

public protocol PostArticleRepository: Sendable {
    func fetchArticles(cursor: Int64?) async throws -> PostArticlesPage
    func fetchBlogSources() async throws -> [PostBlogSource]
}
