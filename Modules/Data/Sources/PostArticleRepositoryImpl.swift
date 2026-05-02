import Domain
import Entity
import Foundation

private enum PostNetworkDefaults {
    static let baseURL = URL(string: "https://www.handev.site/api")!
    static let requestTimeout: TimeInterval = 8
    static let retryPolicy = HTTPRetryPolicy(maxRetryCount: 2)
}

public actor PostArticleRepositoryImpl: PostArticleRepository {
    private let baseURL: URL
    private let httpClient: any HTTPClient
    private let retryPolicy: HTTPRetryPolicy

    public init() {
        self.init(
            baseURL: PostNetworkDefaults.baseURL,
            httpClient: URLSessionHTTPClient.shared,
            retryPolicy: PostNetworkDefaults.retryPolicy
        )
    }

    init(
        baseURL: URL = PostNetworkDefaults.baseURL,
        httpClient: any HTTPClient = URLSessionHTTPClient.shared,
        retryPolicy: HTTPRetryPolicy = PostNetworkDefaults.retryPolicy
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.retryPolicy = retryPolicy
    }

    public func fetchArticles(cursor: Int64?) async throws -> PostArticlesPage {
        let envelope: PostArticlesAPIEnvelopeDTO = try await requestEnvelope(
            path: "v1/articles",
            queryItems: cursor.map { [URLQueryItem(name: "cursor", value: String($0))] } ?? []
        )

        guard let payload = envelope.data else {
            throw PostContentError.decoding(message: "articles data is empty")
        }

        let items = payload.data.map { entry in
            PostArticleListItem(
                id: entry.article.id,
                title: entry.article.title,
                articleLink: entry.article.link,
                blogName: entry.blog.name,
                blogLink: entry.blog.link,
                publishedAtMillis: entry.article.pubDate
            )
        }

        return PostArticlesPage(
            items: items,
            hasNext: payload.hasNext,
            nextCursor: payload.nextCursor
        )
    }

    public func fetchBlogSources() async throws -> [PostBlogSource] {
        let envelope: PostBlogsAPIEnvelopeDTO = try await requestEnvelope(path: "v1/blogs")

        guard let payload = envelope.data else {
            throw PostContentError.decoding(message: "blogs data is empty")
        }

        return payload.map { entry in
            PostBlogSource(
                order: entry.order,
                link: entry.link,
                name: entry.name
            )
        }
    }

    private func requestEnvelope<T: PostAPIEnvelopeDTO>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )

        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw PostContentError.transport(message: "요청 URL을 생성할 수 없습니다.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = PostNetworkDefaults.requestTimeout

        do {
            let response = try await httpClient.decodedResponse(
                for: request,
                as: T.self,
                keyDecodingStrategy: .convertFromSnakeCase,
                retryPolicy: retryPolicy,
                shouldRetry: { Self.mapTransportError($0).isRetriable },
                validateResponse: { response in
                    guard response.body.resultType.uppercased() == "SUCCESS" else {
                        throw Self.mapAPIError(
                            statusCode: response.statusCode,
                            errorPayload: response.body.errorMessage
                        )
                    }
                }
            )

            return response.body
        } catch let error as PostContentError {
            throw error
        } catch {
            throw Self.mapTransportError(error)
        }
    }

    private static func mapAPIError(statusCode: Int, errorPayload: PostAPIErrorPayloadDTO?) -> PostContentError {
        let errorCode = errorPayload?.code
        let message = errorPayload?.message

        if let errorCode {
            switch errorCode {
            case "BAD_REQUEST":
                return .invalidRequest(message: message)
            case "NOT_FOUND_DATA":
                return .notFound(message: message)
            case "KAKAO_CLIENT_ERROR":
                return .invalidRequest(message: message)
            case "KAKAO_SERVER_ERROR":
                return .serverError(message: message)
            case "KID_NOT_MATCH":
                return .unauthorized(message: message)
            case "DUPLICATED_WEBHOOK":
                return .duplicatedWebhook(message: message)
            case "INVALID_WEBHOOK_PLATFORM":
                return .invalidWebhookPlatform(message: message)
            case "INVALID_WEBHOOK_URL":
                return .invalidWebhookURL(message: message)
            default:
                return .unknown(code: errorCode, message: message)
            }
        }

        switch statusCode {
        case 400:
            return .invalidRequest(message: message)
        case 401:
            return .unauthorized(message: message)
        case 403:
            return .forbidden(message: message)
        case 404:
            return .notFound(message: message)
        case 429:
            return .rateLimit(message: message)
        case 500...599:
            return .serverError(message: message)
        default:
            return .unknown(code: nil, message: message)
        }
    }

    private static func mapTransportError(_ error: Error) -> PostContentError {
        if let error = error as? PostContentError {
            return error
        }

        if let error = error as? HTTPClientError {
            switch error {
            case .invalidResponse:
                return .transport(message: "유효하지 않은 응답입니다.")
            case .timeout:
                return .timeout
            case let .transport(message):
                return .transport(message: message)
            case let .decoding(message):
                return .decoding(message: message)
            }
        }

        return .transport(message: error.localizedDescription)
    }
}

private protocol PostAPIEnvelopeDTO: Decodable {
    var resultType: String { get }
    var errorMessage: PostAPIErrorPayloadDTO? { get }
}

extension PostArticlesAPIEnvelopeDTO: PostAPIEnvelopeDTO {}
extension PostBlogsAPIEnvelopeDTO: PostAPIEnvelopeDTO {}
