import Core

public enum AmplitudeEvent: Sendable, Equatable {
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
        case .appOpened:
            "App Opened"
        case .tabSelected:
            "Tab Selected"
        case .homeCategorySelected:
            "Home Category Selected"
        case .homeLessonOpened:
            "Home Lesson Opened"
        case .homeNextLessonTapped:
            "Home Next Lesson Tapped"
        case .homeConceptSaved:
            "Home Concept Saved"
        case .homeConceptUnsaved:
            "Home Concept Unsaved"
        case .postListViewed:
            "Post List Viewed"
        case .postRefreshTapped:
            "Post Refresh Tapped"
        case .postRetryTapped:
            "Post Retry Tapped"
        case .postFilterSelected:
            "Post Filter Selected"
        case .postLoadMoreTapped:
            "Post Load More Tapped"
        case .postOpened:
            "Post Opened"
        case .postSaved:
            "Post Saved"
        case .postUnsaved:
            "Post Unsaved"
        case .quizHomeViewed:
            "Quiz Home Viewed"
        case .quizRefreshTapped:
            "Quiz Refresh Tapped"
        case .quizCategorySelected:
            "Quiz Category Selected"
        case .quizQuestionOpened:
            "Quiz Question Opened"
        case .quizAnswerSubmitted:
            "Quiz Answer Submitted"
        case .quizCompleted:
            "Quiz Completed"
        case .quizSaved:
            "Quiz Saved"
        case .quizUnsaved:
            "Quiz Unsaved"
        case .savedTabSelected:
            "Saved Tab Selected"
        case .savedConceptOpened:
            "Saved Concept Opened"
        case .savedQuizOpened:
            "Saved Quiz Opened"
        case .savedFullQuizStarted:
            "Saved Full Quiz Started"
        }
    }

    public var properties: [String: AnalyticsValue] {
        switch self {
        case .appOpened, .postListViewed, .quizHomeViewed, .postRefreshTapped, .postRetryTapped, .postLoadMoreTapped, .savedFullQuizStarted, .quizRefreshTapped:
            [:]

        case let .tabSelected(tab):
            ["tab": .string(tab)]

        case let .homeCategorySelected(categoryID):
            ["category_id": .string(categoryID)]

        case let .homeLessonOpened(categoryID, lessonID),
             let .homeNextLessonTapped(categoryID, lessonID):
            [
                "category_id": .string(categoryID),
                "lesson_id": .string(lessonID)
            ]

        case let .homeConceptSaved(categoryID, conceptID),
             let .homeConceptUnsaved(categoryID, conceptID),
             let .savedConceptOpened(categoryID, conceptID):
            [
                "category_id": .string(categoryID),
                "concept_id": .string(conceptID)
            ]

        case let .postFilterSelected(filterID):
            ["filter_id": .string(filterID)]

        case let .postOpened(articleID, source):
            [
                "article_id": .int(Int(articleID)),
                "source": .string(source)
            ]

        case let .postSaved(articleID),
             let .postUnsaved(articleID):
            ["article_id": .int(Int(articleID))]

        case let .quizCategorySelected(categoryID):
            ["category_id": .string(categoryID)]

        case let .quizQuestionOpened(questionID),
             let .savedQuizOpened(questionID),
             let .quizSaved(questionID),
             let .quizUnsaved(questionID):
            ["question_id": .int(questionID)]

        case let .quizAnswerSubmitted(questionID, isCorrect):
            [
                "question_id": .int(questionID),
                "is_correct": .bool(isCorrect)
            ]

        case let .quizCompleted(totalCount, correctCount):
            [
                "total_count": .int(totalCount),
                "correct_count": .int(correctCount)
            ]

        case let .savedTabSelected(tab):
            ["tab": .string(tab)]
        }
    }
}

public extension AnalyticsClient {
    func track(_ event: AmplitudeEvent) async {
        await track(event.analyticsEvent)
    }
}
