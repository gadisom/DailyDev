import ComposableArchitecture
import Core
import Entity

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Platform: String, Equatable, Sendable {
            case iOS
            case macOS
        }

        public var platform: Platform
        public var environment: AppEnvironment
        public var categories: [CSCategoryDefinition]
        public var selectedCategoryID: String?
        public var selectedContent: CSCategoryContent?
        public var isLoading: Bool
        public var errorMessage: String?

        public init(
            platform: Platform,
            environment: AppEnvironment
        ) {
            self.platform = platform
            self.environment = environment
            self.categories = []
            self.selectedCategoryID = nil
            self.selectedContent = nil
            self.isLoading = false
            self.errorMessage = nil
        }
    }

    public enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case task
        case categoriesLoaded(Result<[CSCategoryDefinition], Error>)
        case categorySelected(String)
        case categoryContentLoaded(Result<CSCategoryContent, Error>)
    }

    @Dependency(\.csContentClient) var csContentClient

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .task:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let categories = try await csContentClient.fetchCategories()
                        await send(.categoriesLoaded(.success(categories)))
                    } catch {
                        await send(.categoriesLoaded(.failure(error)))
                    }
                }

            case let .categoriesLoaded(.success(categories)):
                state.categories = categories
                state.isLoading = false

                guard let first = categories.first else {
                    return .none
                }

                state.selectedCategoryID = first.id
                return .send(.categorySelected(first.id))

            case let .categoriesLoaded(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .categorySelected(categoryID):
                guard let category = state.categories.first(where: { $0.id == categoryID }) else {
                    return .none
                }

                state.selectedCategoryID = categoryID
                state.isLoading = true
                state.errorMessage = nil

                return .run { send in
                    do {
                        let content = try await csContentClient.fetchCategoryContent(category.id)
                        await send(.categoryContentLoaded(.success(content)))
                    } catch {
                        await send(.categoryContentLoaded(.failure(error)))
                    }
                }

            case let .categoryContentLoaded(.success(content)):
                state.selectedContent = content
                state.isLoading = false
                return .none

            case let .categoryContentLoaded(.failure(error)):
                state.selectedContent = nil
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}
