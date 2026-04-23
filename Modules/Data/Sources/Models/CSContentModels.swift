import Entity
import Foundation

struct CSCategoryDTO: Decodable {
    let categorySlug: String
    let categoryTitle: String?
    let displayOrder: Int
}

struct CSContentItemDTO: Decodable {
    let categoryTitle: String?
    let subcategorySlug: String
    let subcategoryTitle: String?
    let slug: String
    let title: String
    let summary: String?
    let blocks: [JSONDictionary]
    let relatedItemIds: [String]?
    let keywords: [String]?
    let displayOrder: Int
}

struct ParsedBlocks {
    let definitionBody: [String]
    let body: [String]
    let keyPoints: [String]
    let interviewPrompts: [String]
    let checkQuestions: [String]
    let imageURLs: [String]
    let imageURL: String?
    let imageAspectRatio: Double?
    let orderedBlocks: [CSStudyBlock]
}

typealias JSONDictionary = [String: JSONValue]

enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.typeMismatch(
                JSONValue.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value")
            )
        }
    }

    var stringValue: String? {
        switch self {
        case let .string(value):
            return value
        case let .number(value):
            return String(value)
        case let .bool(value):
            return String(value)
        default:
            return nil
        }
    }

    var doubleValue: Double? {
        switch self {
        case let .number(value):
            return value
        case let .string(value):
            return Double(value)
        default:
            return nil
        }
    }

    var arrayValue: [JSONValue]? {
        if case let .array(value) = self { return value }
        return nil
    }

    var objectValue: [String: JSONValue]? {
        if case let .object(value) = self { return value }
        return nil
    }
}
