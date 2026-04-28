import Core

public enum AppEvent: Sendable, Equatable {
    case appOpened
    case tabSelected(tab: String)

    case homeCategorySelected(categoryID: String)
    case homeLessonOpened(categoryID: String, lessonID: String)
    case homeNextLessonTapped(categoryID: String, lessonID: String)
    case homeConceptSaved(categoryID: String, conceptID: String)
    case homeConceptUnsaved(categoryID: String, conceptID: String)

    case postListViewed
    case postRefreshTapped
    case postRetryTapped
    case postFilterSelected(filterID: String)
    case postLoadMoreTapped
    case postOpened(articleID: Int64, source: String)
    case postSaved(articleID: Int64)
    case postUnsaved(articleID: Int64)

    case quizHomeViewed
    case quizRefreshTapped
    case quizCategorySelected(categoryID: String)
    case quizQuestionOpened(questionID: Int)
    case quizAnswerSubmitted(questionID: Int, isCorrect: Bool)
    case quizCompleted(totalCount: Int, correctCount: Int)
    case quizSaved(questionID: Int)
    case quizUnsaved(questionID: Int)

    case savedTabSelected(tab: String)
    case savedConceptOpened(categoryID: String, conceptID: String)
    case savedQuizOpened(questionID: Int)
    case savedFullQuizStarted

    public var analyticsEvent: AnalyticsEvent {
        AnalyticsEvent(name: name, properties: properties)
    }

    public var name: String {
        switch self {
        case .appOpened: "app_opened"
        case .tabSelected: "tab_selected"
        case .homeCategorySelected: "home_category_selected"
        case .homeLessonOpened: "home_lesson_opened"
        case .homeNextLessonTapped: "home_next_lesson_tapped"
        case .homeConceptSaved: "home_concept_saved"
        case .homeConceptUnsaved: "home_concept_unsaved"
        case .postListViewed: "post_list_viewed"
        case .postRefreshTapped: "post_refresh_tapped"
        case .postRetryTapped: "post_retry_tapped"
        case .postFilterSelected: "post_filter_selected"
        case .postLoadMoreTapped: "post_load_more_tapped"
        case .postOpened: "post_opened"
        case .postSaved: "post_saved"
        case .postUnsaved: "post_unsaved"
        case .quizHomeViewed: "quiz_home_viewed"
        case .quizRefreshTapped: "quiz_refresh_tapped"
        case .quizCategorySelected: "quiz_category_selected"
        case .quizQuestionOpened: "quiz_question_opened"
        case .quizAnswerSubmitted: "quiz_answer_submitted"
        case .quizCompleted: "quiz_completed"
        case .quizSaved: "quiz_saved"
        case .quizUnsaved: "quiz_unsaved"
        case .savedTabSelected: "saved_tab_selected"
        case .savedConceptOpened: "saved_concept_opened"
        case .savedQuizOpened: "saved_quiz_opened"
        case .savedFullQuizStarted: "saved_full_quiz_started"
        }
    }

    public var properties: [String: AnalyticsValue] {
        switch self {
        case .appOpened, .postListViewed, .quizHomeViewed, .postRefreshTapped,
             .postRetryTapped, .postLoadMoreTapped, .savedFullQuizStarted, .quizRefreshTapped:
            [:]

        case let .tabSelected(tab):
            ["tab": .string(tab)]

        case let .homeCategorySelected(categoryID):
            ["category_id": .string(categoryID)]

        case let .homeLessonOpened(categoryID, lessonID),
             let .homeNextLessonTapped(categoryID, lessonID):
            ["category_id": .string(categoryID), "lesson_id": .string(lessonID)]

        case let .homeConceptSaved(categoryID, conceptID),
             let .homeConceptUnsaved(categoryID, conceptID),
             let .savedConceptOpened(categoryID, conceptID):
            ["category_id": .string(categoryID), "concept_id": .string(conceptID)]

        case let .postFilterSelected(filterID):
            ["filter_id": .string(filterID)]

        case let .postOpened(articleID, source):
            ["article_id": .int(Int(articleID)), "source": .string(source)]

        case let .postSaved(articleID), let .postUnsaved(articleID):
            ["article_id": .int(Int(articleID))]

        case let .quizCategorySelected(categoryID):
            ["category_id": .string(categoryID)]

        case let .quizQuestionOpened(questionID),
             let .savedQuizOpened(questionID),
             let .quizSaved(questionID),
             let .quizUnsaved(questionID):
            ["question_id": .int(questionID)]

        case let .quizAnswerSubmitted(questionID, isCorrect):
            ["question_id": .int(questionID), "is_correct": .bool(isCorrect)]

        case let .quizCompleted(totalCount, correctCount):
            ["total_count": .int(totalCount), "correct_count": .int(correctCount)]

        case let .savedTabSelected(tab):
            ["tab": .string(tab)]
        }
    }
}

public extension AnalyticsClient {
    func track(_ event: AppEvent) async {
        await track(event.analyticsEvent)
    }
}
