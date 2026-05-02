import Foundation

public protocol SupabaseRequesting {
    func request<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]
    ) async throws -> T
}

public enum SupabaseClientError: LocalizedError, Equatable {
    case missingAnonKey
    case invalidURL
    case invalidStatusCode(Int)
    case invalidResponse
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingAnonKey:
            return "SUPABASE_PUBLISHABLE_KEY(또는 SUPABASE_ANON_KEY)가 설정되지 않았습니다."
        case .invalidURL:
            return "Supabase 요청 URL 생성에 실패했습니다."
        case let .invalidStatusCode(code):
            return "Supabase 요청 실패 (status: \(code))."
        case .invalidResponse:
            return "유효하지 않은 응답입니다."
        case let .decodingFailed(message):
            return "Supabase 응답 디코딩 실패: \(message)"
        }
    }
}

public struct SupabaseClient: SupabaseRequesting {
    private let baseURL: URL
    private let anonKey: String?
    private let decoder: JSONDecoder
    private let httpClient: any HTTPClient

    public init(
        baseURL: URL = URL(string: "https://yfkrjmcfpvnnsbgehvjm.supabase.co/rest/v1")!,
        anonKey: String? = nil,
        httpClient: any HTTPClient = URLSessionHTTPClient.shared
    ) {
        self.baseURL = baseURL
        self.anonKey = Self.resolveAnonKey(explicit: anonKey)
        self.httpClient = httpClient

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    public func request<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        guard let anonKey, !anonKey.isEmpty else {
            throw SupabaseClientError.missingAnonKey
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw SupabaseClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let response = try await httpClient.data(for: request)

        guard (200...299).contains(response.statusCode) else {
            #if DEBUG
            let bodyPreview = String(data: response.body, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(1200)
            let headerPreview = response.headers
                .compactMap { key, value in
                    "\(key): \(value)"
                }
                .joined(separator: ", ")
            print("""
            [SupabaseClient] ❌ request failed
            status: \(response.statusCode)
            url: \(url.absoluteString)
            headers: \(headerPreview)
            body: \(bodyPreview ?? "<non-utf8-body>")
            """)
            #endif
            throw SupabaseClientError.invalidStatusCode(response.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: response.body)
        } catch {
            throw SupabaseClientError.decodingFailed(error.localizedDescription)
        }
    }

    private static func resolveAnonKey(explicit: String?) -> String? {
        if let explicit, !explicit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return explicit.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let publishable = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String,
           !publishable.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return publishable.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let anonymous = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           !anonymous.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return anonymous.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let publishable = ProcessInfo.processInfo.environment["SUPABASE_PUBLISHABLE_KEY"],
           !publishable.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return publishable.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let anonymous = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
           !anonymous.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return anonymous.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }
}
