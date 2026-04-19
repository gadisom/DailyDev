import Foundation
import Entity

public struct CSBundleRepository {
    private let bundle: Bundle
    private let subdirectory: String
    private let decoder: JSONDecoder

    public init(
        bundle: Bundle = .main,
        subdirectory: String = "CS",
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.bundle = bundle
        self.subdirectory = subdirectory
        self.decoder = decoder
    }

    public func fetchCategories() throws -> CSCategoriesIndex {
        try decode(CSCategoriesIndex.self, resource: "categories.json")
    }

    public func fetchCategoryContent(prodFile: String) throws -> CSCategoryContent {
        try decode(CSCategoryContent.self, resource: prodFile)
    }

    private func decode<T: Decodable>(_ type: T.Type, resource: String) throws -> T {
        guard let url = bundle.url(
            forResource: resource,
            withExtension: nil,
            subdirectory: subdirectory
        ) else {
            throw CSBundleRepositoryError.resourceNotFound(resource)
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch let error as CSBundleRepositoryError {
            throw error
        } catch {
            throw CSBundleRepositoryError.decodingFailed(
                resource: resource,
                underlying: error
            )
        }
    }
}

public enum CSBundleRepositoryError: LocalizedError, Equatable {
    case resourceNotFound(String)
    case decodingFailed(resource: String, underlying: Error)

    public static func == (lhs: CSBundleRepositoryError, rhs: CSBundleRepositoryError) -> Bool {
        switch (lhs, rhs) {
        case let (.resourceNotFound(left), .resourceNotFound(right)):
            return left == right
        case let (.decodingFailed(left, _), .decodingFailed(right, _)):
            return left == right
        default:
            return false
        }
    }

    public var errorDescription: String? {
        switch self {
        case let .resourceNotFound(resource):
            return "Missing bundled resource: \(resource)"
        case let .decodingFailed(resource, underlying):
            return "Failed to decode \(resource): \(underlying.localizedDescription)"
        }
    }
}
