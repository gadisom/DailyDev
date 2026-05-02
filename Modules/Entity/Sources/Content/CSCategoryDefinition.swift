import Foundation

public struct CSCategoryDefinition: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let displayOrder: Int

    public init(
        id: String,
        title: String,
        displayOrder: Int
    ) {
        self.id = id
        self.title = title
        self.displayOrder = displayOrder
    }
}
