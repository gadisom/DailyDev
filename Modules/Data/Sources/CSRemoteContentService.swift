import Entity
import Foundation

public struct CSRemoteContentService: Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(
        baseURL: URL = URL(string: "https://yfkrjmcfpvnnsbgehvjm.supabase.co/storage/v1/object/public/CSContent/CS")!,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    public func fetchManifest() async throws -> CSContentManifest {
        try await decode(CSContentManifest.self, path: "manifest.json")
    }

    public func fetchCategories() async throws -> CSCategoriesIndex {
        try await decode(CSCategoriesIndex.self, path: "categories.json")
    }

    public func fetchCategoryContent(prodFile: String) async throws -> CSCategoryContent {
        try await decode(CSCategoryContent.self, path: prodFile)
    }

    private func decode<T: Decodable>(_ type: T.Type, path: String) async throws -> T {
        let url = baseURL.appending(path: path)
        let (data, response) = try await session.data(from: url)

        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw CSRemoteContentServiceError.invalidStatusCode(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw CSRemoteContentServiceError.decodingFailed(path: path, underlying: error)
        }
    }
}

public enum CSRemoteContentServiceError: LocalizedError, Equatable {
    case invalidStatusCode(Int)
    case decodingFailed(path: String, underlying: Error)

    public static func == (lhs: CSRemoteContentServiceError, rhs: CSRemoteContentServiceError) -> Bool {
        switch (lhs, rhs) {
        case let (.invalidStatusCode(left), .invalidStatusCode(right)):
            return left == right
        case let (.decodingFailed(left, _), .decodingFailed(right, _)):
            return left == right
        default:
            return false
        }
    }

    public var errorDescription: String? {
        switch self {
        case let .invalidStatusCode(statusCode):
            return "Remote content request failed with status code \(statusCode)."
        case let .decodingFailed(path, underlying):
            return "Failed to decode remote content at \(path): \(underlying.localizedDescription)"
        }
    }
}
