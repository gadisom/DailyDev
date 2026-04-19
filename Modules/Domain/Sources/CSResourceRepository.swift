import Foundation
import Entity

public protocol CSResourceRepository: Sendable {
    func syncIfNeeded(forceRefresh: Bool) async throws -> CSContentManifest
    func fetchManifest() async throws -> CSContentManifest
    func fetchCategories() async throws -> [CSCategoryDefinition]
    func fetchCategoryContent(prodFile: String) async throws -> CSCategoryContent
}
