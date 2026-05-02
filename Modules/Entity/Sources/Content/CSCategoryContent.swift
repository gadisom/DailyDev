import Foundation

public struct CSCategoryContent: Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let displayOrder: Int
    public let subcategories: [CSSubcategory]

    public init(
        id: String,
        title: String,
        displayOrder: Int,
        subcategories: [CSSubcategory]
    ) {
        self.id = id
        self.title = title
        self.displayOrder = displayOrder
        self.subcategories = subcategories
    }
}

public struct CSSubcategory: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let displayOrder: Int
    public let items: [CSStudyItem]

    public init(
        id: String,
        title: String,
        displayOrder: Int,
        items: [CSStudyItem]
    ) {
        self.id = id
        self.title = title
        self.displayOrder = displayOrder
        self.items = items
    }
}

public struct CSStudyItem: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let displayOrder: Int
    public let imageUrls: [String]?
    public let imageUrl: String?
    public let imageAspectRatio: Double?
    public let summary: String
    public let keywords: [String]
    public let body: [String]
    public let keyPoints: [String]
    public let interviewPrompts: [String]
    public let checkQuestions: [String]
    public let relatedItemIds: [String]
    public let orderedBlocks: [CSStudyBlock]?

    public init(
        id: String,
        title: String,
        displayOrder: Int,
        imageUrls: [String]? = nil,
        imageUrl: String? = nil,
        imageAspectRatio: Double? = nil,
        summary: String,
        keywords: [String],
        body: [String],
        keyPoints: [String],
        interviewPrompts: [String],
        checkQuestions: [String],
        relatedItemIds: [String],
        orderedBlocks: [CSStudyBlock]? = nil
    ) {
        self.id = id
        self.title = title
        self.displayOrder = displayOrder
        self.imageUrls = imageUrls
        self.imageUrl = imageUrl
        self.imageAspectRatio = imageAspectRatio
        self.summary = summary
        self.keywords = keywords
        self.body = body
        self.keyPoints = keyPoints
        self.interviewPrompts = interviewPrompts
        self.checkQuestions = checkQuestions
        self.relatedItemIds = relatedItemIds
        self.orderedBlocks = orderedBlocks
    }
}

public struct CSStudyBlock: Codable, Equatable, Sendable {
    public let type: String
    public let items: [String]

    public init(type: String, items: [String]) {
        self.type = type
        self.items = items
    }
}
