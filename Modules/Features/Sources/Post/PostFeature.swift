import ComposableArchitecture
import Entity
import Foundation

@Reducer
public struct PostFeature {
    @ObservableState
    public struct State: Equatable {
        public static let allFilterID = "__all__"

        public struct FilterChip: Identifiable, Equatable, Sendable {
            public let id: String
            public let title: String
            public let count: Int

            public init(id: String, title: String, count: Int) {
                self.id = id
                self.title = title
                self.count = count
            }
        }

        public enum LoadPhase: Equatable {
            case idle
            case loading
            case reconnecting
            case content
            case empty
            case error
        }

        public var phase: LoadPhase
        public var articles: [PostArticleListItem]
        public var hasNext: Bool
        public var nextCursor: Int64?
        public var message: String
        public var canRetry: Bool
        public var isLoading: Bool
        public var selectedFilterID: String

        public var visibleArticles: [PostArticleListItem] {
            guard selectedFilterID != Self.allFilterID else { return articles }
            return articles.filter { Self.blogFilterID(from: $0) == selectedFilterID }
        }

        public var filterChips: [FilterChip] {
            var buckets: [String: (title: String, count: Int)] = [:]

            for article in articles {
                let id = Self.blogFilterID(from: article)
                let title = Self.blogDisplayName(from: article)

                if let existing = buckets[id] {
                    buckets[id] = (title: existing.title, count: existing.count + 1)
                } else {
                    buckets[id] = (title: title, count: 1)
                }
            }

            let dynamicChips = buckets
                .map { key, value in
                    FilterChip(id: key, title: value.title, count: value.count)
                }
                .sorted { lhs, rhs in
                    return lhs.title.localizedCompare(rhs.title) == .orderedAscending
                }

            return [FilterChip(id: Self.allFilterID, title: "전체", count: articles.count)] + dynamicChips
        }

        public init(
            phase: LoadPhase = .idle,
            articles: [PostArticleListItem] = [],
            hasNext: Bool = false,
            nextCursor: Int64? = nil,
            message: String = "",
            canRetry: Bool = false,
            isLoading: Bool = false,
            selectedFilterID: String = Self.allFilterID
        ) {
            self.phase = phase
            self.articles = articles
            self.hasNext = hasNext
            self.nextCursor = nextCursor
            self.message = message
            self.canRetry = canRetry
            self.isLoading = isLoading
            self.selectedFilterID = selectedFilterID
        }

        private static func blogDisplayName(from article: PostArticleListItem) -> String {
            let trimmed = article.blogName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
            if let host = URL(string: article.blogLink)?.host {
                return host.replacingOccurrences(of: "www.", with: "")
            }
            return "기타"
        }

        private static func blogFilterID(from article: PostArticleListItem) -> String {
            blogDisplayName(from: article)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        }
    }

    public enum Action: Sendable {
        case task
        case refreshRequested
        case retryTapped
        case rowAppeared(Int64)
        case filterSelected(String)
        case loadMoreTapped

        case _load(reset: Bool)
        case _loadResponse(reset: Bool, Result<PostArticlesPage, PostContentError>)
    }

    @Dependency(\.postContentClient) var postContentClient
    @Dependency(\.analyticsClient) var analyticsClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                guard state.phase == .idle || state.phase == .empty else { return .none }
                return .send(._load(reset: true))

            case .refreshRequested:
                return .merge(
                    .run { _ in
                        await analyticsClient.track(.postRefreshTapped)
                    },
                    .send(._load(reset: true))
                )

            case .retryTapped:
                let trackRetry: Effect<Action> = .run { _ in
                    await analyticsClient.track(.postRetryTapped)
                }

                if state.articles.isEmpty {
                    return .merge(trackRetry, .send(._load(reset: true)))
                }
                if state.hasNext {
                    return .merge(trackRetry, .send(._load(reset: false)))
                }
                return .merge(trackRetry, .send(._load(reset: true)))

            case let .rowAppeared(articleID):
                guard !state.isLoading else { return .none }
                guard state.phase == .content || state.phase == .reconnecting else { return .none }
                guard state.hasNext, let last = state.visibleArticles.last, last.id == articleID else { return .none }
                return .send(._load(reset: false))

            case let .filterSelected(filterID):
                state.selectedFilterID = filterID
                let trackFilter: Effect<Action> = .run { _ in
                    await analyticsClient.track(.postFilterSelected(filterID: filterID))
                }

                if state.visibleArticles.isEmpty && state.hasNext && !state.isLoading && !state.articles.isEmpty {
                    return .merge(trackFilter, .send(._load(reset: false)))
                }
                return trackFilter

            case .loadMoreTapped:
                guard state.hasNext, !state.isLoading else { return .none }
                return .merge(
                    .run { _ in
                        await analyticsClient.track(.postLoadMoreTapped)
                    },
                    .send(._load(reset: false))
                )

            case let ._load(reset):
                guard !state.isLoading else { return .none }
                state.isLoading = true

                if reset {
                    state.phase = .loading
                    state.articles = []
                    state.hasNext = false
                    state.message = ""
                    state.nextCursor = nil
                    state.canRetry = false
                    state.selectedFilterID = State.allFilterID
                }

                let cursor = reset ? nil : state.nextCursor
                return .run { send in
                    do {
                        let page = try await postContentClient.fetchArticles(cursor)
                        await send(._loadResponse(reset: reset, .success(page)))
                    } catch let error as PostContentError {
                        await send(._loadResponse(reset: reset, .failure(error)))
                    } catch {
                        await send(
                            ._loadResponse(
                                reset: reset,
                                .failure(.unknown(code: nil, message: error.localizedDescription))
                            )
                        )
                    }
                }

            case let ._loadResponse(reset, .success(page)):
                state.isLoading = false
                let previousVisibleCount = state.visibleArticles.count

                if reset {
                    state.articles = page.items
                } else {
                    state.articles.append(contentsOf: page.items)
                }
                state.hasNext = page.hasNext
                state.nextCursor = page.nextCursor
                state.phase = state.articles.isEmpty ? .empty : .content
                state.canRetry = false
                state.message = ""

                if !state.filterChips.contains(where: { $0.id == state.selectedFilterID }) {
                    state.selectedFilterID = State.allFilterID
                }

                if state.selectedFilterID != State.allFilterID,
                   !reset,
                   state.hasNext,
                   state.visibleArticles.count == previousVisibleCount {
                    return .send(._load(reset: false))
                }
                return .none

            case let ._loadResponse(reset, .failure(error)):
                state.isLoading = false
                state.message = error.userMessage
                state.canRetry = true
                state.phase = state.articles.isEmpty ? .error : .reconnecting
                if reset {
                    state.hasNext = false
                }
                return .none
            }
        }
    }
}
