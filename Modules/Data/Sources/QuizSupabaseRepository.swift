import Foundation
import Domain
import Entity

public actor QuizSupabaseRepository: QuizRepository {
    private let client: SupabaseRequesting

    public init(
        client: SupabaseRequesting = SupabaseClient()
    ) {
        self.client = client
    }

    public func fetchQuizBank() async throws -> [QuizCategory] {
        async let cats = fetchCategories()
        async let qs = fetchQuestions()
        let (categoryRows, questionRows) = try await (cats, qs)

        return categoryRows.compactMap { categoryRow in
            let questions = questionRows
                .filter { $0.categoryId == categoryRow.id }
                .compactMap(QuizQuestion.init)

            return QuizCategory(dto: categoryRow, questions: questions)
        }
    }

    private func fetchCategories() async throws -> [QuizCategoryDTO] {
        do {
            return try await request(
                path: "quiz_categories",
                queryItems: [.init(name: "order", value: "id.asc")]
            )
        } catch {
            throw mapRequestError(error)
        }
    }

    private func fetchQuestions() async throws -> [QuizQuestionDTO] {
        do {
            return try await request(
                path: "quiz_questions_dev",
                queryItems: [.init(name: "order", value: "id.asc")]
            )
        } catch {
            throw mapRequestError(error)
        }
    }

    private func request<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        do {
            return try await client.request(path: path, queryItems: queryItems)
        } catch {
            throw mapRequestError(error)
        }
    }

    private func mapRequestError(_ error: Error) -> QuizSupabaseRepositoryError {
        if let error = error as? SupabaseClientError {
            switch error {
            case .missingAnonKey:
                return .missingAnonKey
            case .invalidURL:
                return .invalidURL
            case .invalidStatusCode(let code):
                return .invalidStatusCode(code)
            case .invalidResponse:
                return .decodingFailed("유효하지 않은 응답입니다.")
            case .decodingFailed(let message):
                return .decodingFailed(message)
            }
        }

        return .decodingFailed(error.localizedDescription)
    }
}

private extension QuizCategory {
    init?(dto: QuizCategoryDTO, questions: [QuizQuestion]) {
        self.init(
            id: dto.id,
            name: dto.name,
            icon: dto.icon,
            iconColorHex: dto.iconColor,
            iconBackgroundHex: dto.iconBgColor,
            questions: questions
        )
    }
}

private extension QuizQuestion {
    init?(_ dto: QuizQuestionDTO) {
        guard let type = QuizQuestionType(rawValue: dto.type) else { return nil }
        self.init(
            id: dto.id,
            type: type,
            question: dto.question,
            choices: dto.choices,
            correctIndices: dto.parsedCorrectIndices,
            oxAnswer: dto.oxAnswer,
            fillAnswer: dto.fillAnswer,
            explanation: dto.explanation,
            concept: dto.concept,
            tag: dto.tag
        )
    }
}

public enum QuizSupabaseRepositoryError: LocalizedError {
    case missingAnonKey
    case invalidURL
    case invalidStatusCode(Int)
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingAnonKey:          return "SUPABASE_ANON_KEY가 설정되지 않았습니다."
        case .invalidURL:              return "Quiz Supabase 요청 URL 생성 실패."
        case let .invalidStatusCode(c): return "Quiz 요청 실패 (status: \(c))."
        case let .decodingFailed(msg): return "Quiz 디코딩 실패: \(msg)"
        }
    }
}
