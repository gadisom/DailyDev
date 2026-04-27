import Foundation
#if os(iOS)
import ComposableArchitecture
import Data
import Domain
import Entity

struct QuizDataClient: Sendable {
    var fetchQuizBank: @Sendable () async throws -> [QuizCategoryUIModel]

    init(fetchQuizBank: @escaping @Sendable () async throws -> [QuizCategoryUIModel]) {
        self.fetchQuizBank = fetchQuizBank
    }
}

private enum QuizDataClientKey: DependencyKey {
    static let liveValue: QuizDataClient = {
        let repository = QuizSupabaseRepository()
        let fetchQuizBankUseCase = FetchQuizBankUseCase(repository: repository)

        return QuizDataClient(
            fetchQuizBank: {
                let categories = try await fetchQuizBankUseCase.execute()
                return categories
                    .map(QuizCategoryUIModel.init)
                    .sorted {
                        if $0.sortOrder != $1.sortOrder {
                            return $0.sortOrder < $1.sortOrder
                        }
                        return $0.name.localizedCompare($1.name) == .orderedAscending
                    }
            }
        )
    }()
}

extension DependencyValues {
    var quizDataClient: QuizDataClient {
        get { self[QuizDataClientKey.self] }
        set { self[QuizDataClientKey.self] = newValue }
    }
}

#endif
