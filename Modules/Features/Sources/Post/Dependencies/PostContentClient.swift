import ComposableArchitecture
import Data
import Domain
import Entity
import Foundation

public struct PostContentClient: Sendable {
    public var fetchArticles: @Sendable (_ cursor: Int64?) async throws -> PostArticlesPage

    public init(
        fetchArticles: @escaping @Sendable (_ cursor: Int64?) async throws -> PostArticlesPage
    ) {
        self.fetchArticles = fetchArticles
    }
}

private enum PostContentClientKey: DependencyKey {
    static let liveValue: PostContentClient = {
        let repository = PostArticleRepository()
        let useCase = FetchPostArticlesUseCase(repository: repository)

        return PostContentClient(
            fetchArticles: { cursor in
                try await useCase.execute(cursor: cursor)
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
