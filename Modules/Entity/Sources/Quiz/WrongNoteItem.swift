import Foundation

public struct WrongNoteItem: Identifiable {
    public let id = UUID()
    public let chapterNum: String
    public let chapter: String
    public let question: String
    public let tag: String
    public let type: String
    public let relativeDate: String
    public let wrongCount: Int

    public init(
        chapterNum: String,
        chapter: String,
        question: String,
        tag: String,
        type: String,
        relativeDate: String,
        wrongCount: Int
    ) {
        self.chapterNum = chapterNum
        self.chapter = chapter
        self.question = question
        self.tag = tag
        self.type = type
        self.relativeDate = relativeDate
        self.wrongCount = wrongCount
    }
}
