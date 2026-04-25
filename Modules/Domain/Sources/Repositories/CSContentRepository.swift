import Entity
import Foundation

public protocol CSContentRepository: Sendable {
    func fetchCategories() async throws -> [CSCategoryDefinition]
    func fetchCategoryContent(categorySlug: String) async throws -> CSCategoryContent
}
