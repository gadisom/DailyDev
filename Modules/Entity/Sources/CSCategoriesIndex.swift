import Foundation

public struct CSCategoriesIndex: Codable, Equatable, Sendable {
    public let version: Int
    public let categories: [CSCategoryDefinition]

    public init(version: Int, categories: [CSCategoryDefinition]) {
        self.version = version
        self.categories = categories
    }
}
