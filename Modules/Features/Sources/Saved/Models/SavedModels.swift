import SwiftData
import Foundation
import Entity

// MARK: - Saved Concept

@Model
public final class SavedConcept {
    public var conceptID: String
    public var title: String
    public var categoryID: String
    public var categoryTitle: String
    public var summary: String
    public var savedAt: Date

    public init(conceptID: String, title: String, categoryID: String, categoryTitle: String, summary: String) {
        self.conceptID = conceptID
        self.title = title
        self.categoryID = categoryID
        self.categoryTitle = categoryTitle
        self.summary = summary
        self.savedAt = Date()
    }
}

// MARK: - Saved Quiz Question

@Model
public final class SavedQuizQuestion {
    public var questionID: Int
    public var question: String
    public var questionType: String    // "mcq" | "ox" | "fill"
    public var choices: [String]
    public var correctIndex: Int       // legacy — 신규 저장 시에는 correctIndices 사용
    public var correctIndices: [Int]   // 복수 정답 지원. 비어있으면 correctIndex 폴백
    public var oxAnswer: String
    public var fillAnswer: String
    public var explanation: String
    public var concept: String
    public var tag: String
    public var categoryName: String
    public var savedAt: Date

    /// 실제 정답 인덱스 목록. 신규/레거시 모두 안전하게 반환.
    public var resolvedCorrectIndices: [Int] {
        correctIndices.isEmpty ? (correctIndex >= 0 ? [correctIndex] : []) : correctIndices
    }

    public init(
        questionID: Int,
        question: String,
        questionType: String,
        choices: [String],
        correctIndices: [Int],
        oxAnswer: String,
        fillAnswer: String,
        explanation: String,
        concept: String,
        tag: String,
        categoryName: String
    ) {
        self.questionID = questionID
        self.question = question
        self.questionType = questionType
        self.choices = choices
        self.correctIndex = correctIndices.first ?? -1  // legacy compat
        self.correctIndices = correctIndices
        self.oxAnswer = oxAnswer
        self.fillAnswer = fillAnswer
        self.explanation = explanation
        self.concept = concept
        self.tag = tag
        self.categoryName = categoryName
        self.savedAt = Date()
    }
}

// MARK: - Saved Post

@Model
public final class SavedPost {
    public var articleID: Int64
    public var title: String
    public var blogName: String
    public var articleLink: String
    public var publishedAtMillis: Int64
    public var savedAt: Date

    public init(articleID: Int64, title: String, blogName: String, articleLink: String, publishedAtMillis: Int64) {
        self.articleID = articleID
        self.title = title
        self.blogName = blogName
        self.articleLink = articleLink
        self.publishedAtMillis = publishedAtMillis
        self.savedAt = Date()
    }

    public convenience init(from article: PostArticleListItem) {
        self.init(
            articleID: article.id,
            title: article.title,
            blogName: article.blogName,
            articleLink: article.articleLink,
            publishedAtMillis: article.publishedAtMillis
        )
    }
}
