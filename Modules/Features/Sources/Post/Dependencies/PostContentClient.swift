import ComposableArchitecture
import Data
import Domain
import Entity
import Foundation

public struct PostContentClient: Sendable {
    public var fetchArticles: @Sendable (_ cursor: Int64?) async throws -> PostArticlesPage
    public var fetchBlogSources: @Sendable () async throws -> [PostBlogSource]

    public init(
        fetchArticles: @escaping @Sendable (_ cursor: Int64?) async throws -> PostArticlesPage,
        fetchBlogSources: @escaping @Sendable () async throws -> [PostBlogSource]
    ) {
        self.fetchArticles = fetchArticles
        self.fetchBlogSources = fetchBlogSources
    }
}

private enum PostContentClientKey: DependencyKey {
    static let liveValue: PostContentClient = {
        let repository = PostArticleRepository()
        let fetchArticlesUseCase = FetchPostArticlesUseCase(repository: repository)
        let fetchBlogSourcesUseCase = FetchPostBlogSourcesUseCase(repository: repository)

        return PostContentClient(
            fetchArticles: { cursor in
                try await fetchArticlesUseCase.execute(cursor: cursor)
            },
            fetchBlogSources: {
                try await fetchBlogSourcesUseCase.execute()
            }
        )
    }()
}

extension DependencyValues {
    var postContentClient: PostContentClient {
        get { self[PostContentClientKey.self] }
        set { self[PostContentClientKey.self] = newValue }
    }
}
