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
    private let httpClient: any HTTPRequestExecuting

    public init(
        baseURL: URL = URL(string: "https://yfkrjmcfpvnnsbgehvjm.supabase.co/rest/v1")!,
        anonKey: String? = nil,
        httpClient: any HTTPRequestExecuting = URLSessionHTTPClient.shared
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

        let (data, response) = try await httpClient.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseClientError.invalidStatusCode(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
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
