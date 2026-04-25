import Entity
import Foundation

public protocol PostResourceRepository: Sendable {
    func fetchArticles(cursor: Int64?) async throws -> PostArticlesPage
}
