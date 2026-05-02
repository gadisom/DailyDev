import Foundation

public struct HTTPResponse<Body> {
    public let body: Body
    public let statusCode: Int
    public let headers: [AnyHashable: Any]

    public init(body: Body, statusCode: Int, headers: [AnyHashable: Any]) {
        self.body = body
        self.statusCode = statusCode
        self.headers = headers
    }
}

public struct HTTPRetryPolicy: Sendable {
    public static let none = HTTPRetryPolicy(maxRetryCount: 0)

    public let maxRetryCount: Int
    public let baseBackoffSeconds: TimeInterval
    public let maxBackoffSeconds: TimeInterval

    public init(
        maxRetryCount: Int,
        baseBackoffSeconds: TimeInterval = 0.4,
        maxBackoffSeconds: TimeInterval = 2
    ) {
        self.maxRetryCount = maxRetryCount
        self.baseBackoffSeconds = baseBackoffSeconds
        self.maxBackoffSeconds = maxBackoffSeconds
    }
}

public enum HTTPClientError: LocalizedError, Equatable, Sendable {
    case invalidResponse
    case timeout
    case transport(String)
    case decoding(String)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "유효하지 않은 HTTP 응답입니다."
        case .timeout:
            return "HTTP 요청 시간이 초과되었습니다."
        case let .transport(message):
            return "HTTP 요청 실패: \(message)"
        case let .decoding(message):
            return "HTTP 응답 디코딩 실패: \(message)"
        }
    }
}

public enum HTTPJSONKeyDecodingStrategy: Sendable {
    case useDefaultKeys
    case convertFromSnakeCase

    fileprivate func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        switch self {
        case .useDefaultKeys:
            decoder.keyDecodingStrategy = .useDefaultKeys
        case .convertFromSnakeCase:
            decoder.keyDecodingStrategy = .convertFromSnakeCase
        }
        return decoder
    }
}

public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> HTTPResponse<Data>
}

public extension HTTPClient {
    func decodedResponse<T: Decodable>(
        for request: URLRequest,
        as type: T.Type,
        keyDecodingStrategy: HTTPJSONKeyDecodingStrategy = .useDefaultKeys,
        retryPolicy: HTTPRetryPolicy = .none,
        shouldRetry: (Error) -> Bool = HTTPClientError.defaultShouldRetry,
        validateResponse: (HTTPResponse<T>) throws -> Void = { _ in }
    ) async throws -> HTTPResponse<T> {
        var lastError: Error?

        for attempt in 0...retryPolicy.maxRetryCount {
            do {
                let response = try await data(for: request)
                let decoder = keyDecodingStrategy.makeDecoder()
                let body = try decoder.decode(type, from: response.body)
                let decodedResponse = HTTPResponse(
                    body: body,
                    statusCode: response.statusCode,
                    headers: response.headers
                )
                try validateResponse(decodedResponse)
                return decodedResponse
            } catch let error as DecodingError {
                throw HTTPClientError.decoding(error.localizedDescription)
            } catch {
                lastError = error

                guard shouldRetry(error), attempt < retryPolicy.maxRetryCount else {
                    throw error
                }

                let delaySeconds = min(
                    retryPolicy.baseBackoffSeconds * pow(2.0, Double(attempt)),
                    retryPolicy.maxBackoffSeconds
                )
                try await Task.sleep(for: .seconds(delaySeconds))
            }
        }

        throw lastError ?? HTTPClientError.transport("HTTP 요청 재시도 실패")
    }
}

public struct URLSessionHTTPClient: HTTPClient, Sendable {
    public static let shared = URLSessionHTTPClient()

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> HTTPResponse<Data> {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPClientError.invalidResponse
            }

            return HTTPResponse(
                body: data,
                statusCode: httpResponse.statusCode,
                headers: httpResponse.allHeaderFields
            )
        } catch let error as HTTPClientError {
            throw error
        } catch let error as URLError {
            if error.code == .timedOut {
                throw HTTPClientError.timeout
            }
            throw HTTPClientError.transport(error.localizedDescription)
        } catch {
            throw HTTPClientError.transport(error.localizedDescription)
        }
    }
}

public extension HTTPClientError {
    static func defaultShouldRetry(_ error: Error) -> Bool {
        guard let error = error as? HTTPClientError else {
            return false
        }

        switch error {
        case .timeout, .transport:
            return true
        case .invalidResponse, .decoding:
            return false
        }
    }
}
