import Foundation

public struct CSCategoryDefinition: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let displayOrder: Int
    public let devFile: String
    public let prodFile: String

    public init(
        id: String,
        title: String,
        displayOrder: Int,
        devFile: String,
        prodFile: String
    ) {
        self.id = id
        self.title = title
        self.displayOrder = displayOrder
        self.devFile = devFile
        self.prodFile = prodFile
    }
}
