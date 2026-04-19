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
    public let summary: String
    public let keywords: [String]
    public let body: [String]
    public let keyPoints: [String]
    public let interviewPrompts: [String]
    public let checkQuestions: [String]
    public let relatedItemIds: [String]

    public init(
        id: String,
        title: String,
        displayOrder: Int,
        summary: String,
        keywords: [String],
        body: [String],
        keyPoints: [String],
        interviewPrompts: [String],
        checkQuestions: [String],
        relatedItemIds: [String]
    ) {
        self.id = id
        self.title = title
        self.displayOrder = displayOrder
        self.summary = summary
        self.keywords = keywords
        self.body = body
        self.keyPoints = keyPoints
        self.interviewPrompts = interviewPrompts
        self.checkQuestions = checkQuestions
        self.relatedItemIds = relatedItemIds
    }
}
