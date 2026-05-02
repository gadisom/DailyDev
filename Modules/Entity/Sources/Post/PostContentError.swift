import Foundation

public enum PostContentError: Error, Equatable, Sendable {
    case invalidRequest(message: String?)
    case unauthorized(message: String?)
    case forbidden(message: String?)
    case notFound(message: String?)
    case duplicatedWebhook(message: String?)
    case invalidWebhookPlatform(message: String?)
    case invalidWebhookURL(message: String?)
    case rateLimit(message: String?)
    case serverError(message: String?)
    case transport(message: String?)
    case timeout
    case decoding(message: String?)
    case unknown(code: String?, message: String?)

    public var userMessage: String {
        switch self {
        case .invalidRequest:
            return "요청이 올바르지 않습니다. 입력값을 확인해 주세요."
        case .unauthorized:
            return "인증이 필요합니다. 다시 로그인해 주세요."
        case .forbidden:
            return "권한이 없습니다."
        case .notFound:
            return "요청한 데이터를 찾지 못했습니다."
        case .duplicatedWebhook:
            return "이미 등록된 웹훅입니다."
        case .invalidWebhookPlatform:
            return "지원하지 않는 웹훅 플랫폼입니다."
        case .invalidWebhookURL:
            return "웹훅 주소 형식이 올바르지 않습니다."
        case .rateLimit:
            return "요청이 너무 많습니다. 잠시 뒤 다시 시도해 주세요."
        case .serverError:
            return "일시적인 서버 오류가 발생했습니다."
        case .transport:
            return "네트워크 연결을 확인해 주세요."
        case .timeout:
            return "요청이 지연되어 중단되었습니다."
        case .decoding:
            return "응답 데이터 처리 중 문제가 발생했습니다."
        case let .unknown(code, _):
            if let code {
                return "처리할 수 없는 응답입니다. (\(code))"
            }
            return "알 수 없는 오류가 발생했습니다."
        }
    }

    public var isRetriable: Bool {
        switch self {
        case .timeout, .transport, .serverError, .rateLimit, .unknown:
            return true
        case .invalidRequest,
             .unauthorized,
             .forbidden,
             .notFound,
             .duplicatedWebhook,
             .invalidWebhookPlatform,
             .invalidWebhookURL,
             .decoding:
            return false
        }
    }
}
