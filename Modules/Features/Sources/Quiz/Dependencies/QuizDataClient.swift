import Foundation
#if os(iOS)
import ComposableArchitecture
import Data
import Entity
import SwiftUI

public struct QuizDataClient: Sendable {
    public var fetchQuizBank: @Sendable () async throws -> [QuizCategory]

    public init(fetchQuizBank: @escaping @Sendable () async throws -> [QuizCategory]) {
        self.fetchQuizBank = fetchQuizBank
    }
}

private enum QuizDataClientKey: DependencyKey {
    static let liveValue: QuizDataClient = {
        let repository = QuizSupabaseRepository()

        return QuizDataClient(
            fetchQuizBank: {
                let (categoryRows, questionRows) = try await repository.fetchQuizBank()

                return categoryRows
                    .compactMap { row in
                        let questions = questionRows
                            .filter { $0.categoryId == row.id }
                            .compactMap { questionRow in
                                QuizQuestion(row: questionRow)
                            }
                        return QuizCategory(row: row, questions: questions)
                    }
            }
        )
    }()
}

extension DependencyValues {
    public var quizDataClient: QuizDataClient {
        get { self[QuizDataClientKey.self] }
        set { self[QuizDataClientKey.self] = newValue }
    }
}

private extension QuizCategory {
    init(row: QuizCategoryDTO, questions: [QuizQuestion]) {
        self.init(
            id: row.id,
            name: row.name,
            englishName: row.englishName,
            icon: row.icon,
            iconColor: Color(quizHexString: row.iconColor),
            iconBackground: Color(quizHexString: row.iconBgColor),
            questions: questions
        )
    }
}

private extension QuizQuestion {
    init?(row: QuizQuestionDTO) {
        guard let type = QuizQuestionType(rawString: row.type) else {
            return nil
        }

        self.init(
            id: row.id,
            type: type,
            question: row.question,
            choices: row.choices,
            correctIndex: row.correctIndex,
            oxAnswer: row.oxAnswer,
            fillAnswer: row.fillAnswer,
            explanation: row.explanation,
            concept: row.concept,
            tag: row.tag
        )
    }
}

private extension QuizQuestionType {
    init?(rawString: String) {
        switch rawString {
        case "mcq":
            self = .mcq
        case "ox":
            self = .ox
        case "fill":
            self = .fill
        default:
            return nil
        }
    }
}

private extension Color {
    init(quizHexString value: String) {
        var hex = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }

        guard hex.count == 6, let rgb = UInt64(hex, radix: 16) else {
            self = .gray
            return
        }

        let red = Double((rgb >> 16) & 0xFF) / 255
        let green = Double((rgb >> 8) & 0xFF) / 255
        let blue = Double(rgb & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
#endif
