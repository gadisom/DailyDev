import Foundation
import SwiftData

@Model
public final class CSContentManifestRecord {
    @Attribute(.unique) public var id: String
    public var version: Int
    public var updatedAt: String
    public var files: String

    public init(
        id: String = "current",
        version: Int,
        updatedAt: String,
        files: [String]
    ) {
        self.id = id
        self.version = version
        self.updatedAt = updatedAt
        self.files = files.joined(separator: "\n")
    }

    public var fileList: [String] {
        files
            .split(separator: "\n")
            .map(String.init)
    }
}

@Model
public final class CSCategoryRecord {
    @Attribute(.unique) public var id: String
    public var title: String
    public var displayOrder: Int
    public var devFile: String
    public var prodFile: String
    @Relationship(deleteRule: .cascade, inverse: \CSCategoryContentRecord.category)
    public var contents: [CSCategoryContentRecord]

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
        self.contents = []
    }
}

@Model
public final class CSCategoryContentRecord {
    @Attribute(.unique) public var prodFile: String
    public var title: String
    public var displayOrder: Int
    @Attribute(.externalStorage) public var payload: Data
    public var category: CSCategoryRecord?

    public init(
        prodFile: String,
        title: String,
        displayOrder: Int,
        payload: Data,
        category: CSCategoryRecord? = nil
    ) {
        self.prodFile = prodFile
        self.title = title
        self.displayOrder = displayOrder
        self.payload = payload
        self.category = category
    }
}
