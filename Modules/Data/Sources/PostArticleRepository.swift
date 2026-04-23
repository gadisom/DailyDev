import Domain
import Entity
import Foundation

private enum PostNetworkDefaults {
    static let baseURL = URL(string: "https://www.handev.site/api")!
    static let requestTimeout: TimeInterval = 8
    static let resourceTimeout: TimeInterval = 12
    static let maxRetryCount: Int = 2
    static let baseBackoffSeconds: TimeInterval = 0.4
    static let maxBackoffSeconds: TimeInterval = 2
}

protocol PostArticleNetworkServing: Sendable {
    func fetchArticles(cursor: Int64?) async throws -> PostArticlesAPIEnvelope
}

struct PostArticleNetworkClient: PostArticleNetworkServing {
    private let baseURL: URL
    private let transport: any HTTPRequestExecuting
    private let decoder: JSONDecoder

    init(
        baseURL: URL = PostNetworkDefaults.baseURL,
        transport: any HTTPRequestExecuting = URLSessionHTTPClient.shared
    ) {
        self.baseURL = baseURL
        self.transport = transport

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func fetchArticles(cursor: Int64?) async throws -> PostArticlesAPIEnvelope {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("v1/articles"),
            resolvingAgainstBaseURL: false
        )
        if let cursor {
            components?.queryItems = [URLQueryItem(name: "cursor", value: String(cursor))]
        }

        guard let url = components?.url else {
            throw PostContentError.transport(message: "요청 URL을 생성할 수 없습니다.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = PostNetworkDefaults.requestTimeout

        return try await withExponentialRetry {
            do {
                return try await requestArticles(request: request)
            } catch let error as PostContentError {
                throw error
            } catch let error as URLError {
                if error.code == .timedOut {
                    throw PostContentError.timeout
                }
                throw PostContentError.transport(message: error.localizedDescription)
            } catch let error as DecodingError {
                throw PostContentError.decoding(message: error.localizedDescription)
            } catch {
                throw PostContentError.transport(message: error.localizedDescription)
            }
        }
    }

    private func requestArticles(request: URLRequest) async throws -> PostArticlesAPIEnvelope {
        let (data, response) = try await transport.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostContentError.transport(message: "유효하지 않은 응답입니다.")
        }

        let envelope = try decoder.decode(PostArticlesAPIEnvelope.self, from: data)

        if envelope.resultType.uppercased() == "SUCCESS" {
            return envelope
        }

        throw mapHTTPFailure(
            statusCode: httpResponse.statusCode,
            errorCode: envelope.errorMessage?.code,
            message: envelope.errorMessage?.message
        )
    }

    private func mapHTTPFailure(statusCode: Int, errorCode: String?, message: String?) -> PostContentError {
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
                break
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

    private func withExponentialRetry<T>(
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0...PostNetworkDefaults.maxRetryCount {
            do {
                return try await operation()
            } catch {
                let contentError = error as? PostContentError ?? .transport(message: error.localizedDescription)
                lastError = contentError

                if !contentError.isRetriable || attempt >= PostNetworkDefaults.maxRetryCount {
                    throw contentError
                }

                let delaySeconds = min(
                    PostNetworkDefaults.baseBackoffSeconds * pow(2.0, Double(attempt)),
                    PostNetworkDefaults.maxBackoffSeconds
                )
                try await Task.sleep(for: .seconds(delaySeconds))
            }
        }

        throw lastError ?? PostContentError.unknown(code: nil, message: "네트워크 재시도 실패")
    }
}

public actor PostArticleRepository: PostResourceRepository {
    private let client: PostArticleNetworkServing

    public init() {
        self.client = PostArticleNetworkClient()
    }

    init(client: PostArticleNetworkServing) {
        self.client = client
    }

    public func fetchArticles(cursor: Int64?) async throws -> PostArticlesPage {
        let envelope = try await client.fetchArticles(cursor: cursor)

        guard envelope.resultType.uppercased() == "SUCCESS" else {
            throw mapResultTypeFailure(errorPayload: envelope.errorMessage)
        }

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

    private func mapResultTypeFailure(errorPayload: PostAPIErrorPayload?) -> PostContentError {
        let errorCode = errorPayload?.code
        if let errorCode {
            switch errorCode {
            case "BAD_REQUEST":
                return .invalidRequest(message: errorPayload?.message)
            case "NOT_FOUND_DATA":
                return .notFound(message: errorPayload?.message)
            case "KAKAO_CLIENT_ERROR":
                return .invalidRequest(message: errorPayload?.message)
            case "KAKAO_SERVER_ERROR":
                return .serverError(message: errorPayload?.message)
            case "KID_NOT_MATCH":
                return .unauthorized(message: errorPayload?.message)
            case "DUPLICATED_WEBHOOK":
                return .duplicatedWebhook(message: errorPayload?.message)
            case "INVALID_WEBHOOK_PLATFORM":
                return .invalidWebhookPlatform(message: errorPayload?.message)
            case "INVALID_WEBHOOK_URL":
                return .invalidWebhookURL(message: errorPayload?.message)
            default:
                return .unknown(code: errorCode, message: errorPayload?.message)
            }
        }
        return .serverError(message: errorPayload?.message)
    }
}
