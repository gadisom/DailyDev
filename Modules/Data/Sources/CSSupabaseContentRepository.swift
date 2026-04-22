import Entity
import Foundation

public actor CSSupabaseContentRepository {
    private let baseURL: URL
    private let session: URLSession
    private let anonKey: String?
    private let decoder: JSONDecoder

    public init(
        baseURL: URL = URL(string: "https://yfkrjmcfpvnnsbgehvjm.supabase.co/rest/v1")!,
        anonKey: String? = (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String)
            ?? ProcessInfo.processInfo.environment["SUPABASE_PUBLISHABLE_KEY"]
            ?? ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.anonKey = anonKey?.trimmingCharacters(in: .whitespacesAndNewlines)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    public func fetchCategories() async throws -> [CSCategoryDefinition] {
        let rows = try await fetchCategoryRows()
        var categoryMap: [String: (order: Int, title: String?)] = [:]
        for row in rows {
            if let current = categoryMap[row.categorySlug] {
                categoryMap[row.categorySlug] = (
                    order: min(current.order, row.displayOrder),
                    title: current.title ?? Self.normalizedTitle(row.categoryTitle)
                )
            } else {
                categoryMap[row.categorySlug] = (
                    order: row.displayOrder,
                    title: Self.normalizedTitle(row.categoryTitle)
                )
            }
        }

        return categoryMap
            .map { slug, info in
                CSCategoryDefinition(
                    id: slug,
                    title: info.title ?? Self.prettyTitle(from: slug),
                    displayOrder: info.order
                )
            }
            .sorted {
                if $0.displayOrder != $1.displayOrder { return $0.displayOrder < $1.displayOrder }
                return $0.title.localizedCompare($1.title) == .orderedAscending
            }
    }

    public func fetchCategoryContent(categorySlug: String) async throws -> CSCategoryContent {
        let rows = try await fetchContentRows(categorySlug: categorySlug)

        guard !rows.isEmpty else {
            throw CSSupabaseContentRepositoryError.categoryNotFound(categorySlug)
        }

        let categoryTitle = rows
            .compactMap { Self.normalizedTitle($0.categoryTitle) }
            .first ?? Self.prettyTitle(from: categorySlug)
        var grouped: [String: [ContentItemRow]] = [:]
        var subcategoryOrder: [String: Int] = [:]
        var subcategoryTitles: [String: String] = [:]

        for row in rows {
            grouped[row.subcategorySlug, default: []].append(row)
            let existing = subcategoryOrder[row.subcategorySlug]
            subcategoryOrder[row.subcategorySlug] = min(existing ?? row.displayOrder, row.displayOrder)
            if let title = Self.normalizedTitle(row.subcategoryTitle), subcategoryTitles[row.subcategorySlug] == nil {
                subcategoryTitles[row.subcategorySlug] = title
            }
        }

        let subcategories = grouped
            .map { subcategorySlug, itemRows -> CSSubcategory in
                let sortedRows = itemRows.sorted { lhs, rhs in
                    if lhs.displayOrder != rhs.displayOrder {
                        return lhs.displayOrder < rhs.displayOrder
                    }
                    return lhs.title.localizedCompare(rhs.title) == .orderedAscending
                }

                let items = sortedRows.enumerated().map { index, row -> CSStudyItem in
                    let parsed = Self.parseBlocks(row.blocks)
                    let summary = row.summary?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let fallbackSummary = parsed.definitionBody.first ?? parsed.body.first ?? row.title

                    return CSStudyItem(
                        id: row.slug,
                        title: row.title,
                        displayOrder: row.displayOrder == 0 ? index + 1 : row.displayOrder,
                        imageUrls: parsed.imageURLs,
                        imageUrl: parsed.imageURL,
                        imageAspectRatio: parsed.imageAspectRatio,
                        summary: (summary?.isEmpty == false ? summary! : fallbackSummary),
                        keywords: row.keywords ?? [],
                        body: parsed.definitionBody.isEmpty ? parsed.body : parsed.definitionBody,
                        keyPoints: parsed.keyPoints,
                        interviewPrompts: parsed.interviewPrompts,
                        checkQuestions: parsed.checkQuestions,
                        relatedItemIds: row.relatedItemIds ?? [],
                        orderedBlocks: parsed.orderedBlocks
                    )
                }

                return CSSubcategory(
                    id: subcategorySlug,
                    title: subcategoryTitles[subcategorySlug] ?? Self.prettyTitle(from: subcategorySlug),
                    displayOrder: subcategoryOrder[subcategorySlug] ?? 0,
                    items: items
                )
            }
            .sorted {
                if $0.displayOrder != $1.displayOrder { return $0.displayOrder < $1.displayOrder }
                return $0.title.localizedCompare($1.title) == .orderedAscending
            }

        return CSCategoryContent(
            id: categorySlug,
            title: categoryTitle,
            displayOrder: rows.first?.displayOrder ?? 0,
            subcategories: subcategories
        )
    }

    private func fetchCategoryRows() async throws -> [CategoryRow] {
        do {
            return try await request(
                path: "content_items",
                queryItems: [
                    .init(name: "select", value: "category_slug,category_title,display_order"),
                    .init(name: "is_published", value: "eq.true"),
                    .init(name: "order", value: "display_order.asc"),
                ]
            )
        } catch CSSupabaseContentRepositoryError.invalidStatusCode {
            return try await request(
                path: "content_items",
                queryItems: [
                    .init(name: "select", value: "category_slug,display_order"),
                    .init(name: "is_published", value: "eq.true"),
                    .init(name: "order", value: "display_order.asc"),
                ]
            )
        }
    }

    private func fetchContentRows(categorySlug: String) async throws -> [ContentItemRow] {
        do {
            return try await request(
                path: "content_items",
                queryItems: [
                    .init(
                        name: "select",
                        value: "category_slug,category_title,subcategory_slug,subcategory_title,slug,title,summary,blocks,related_item_ids,keywords,display_order"
                    ),
                    .init(name: "is_published", value: "eq.true"),
                    .init(name: "category_slug", value: "eq.\(categorySlug)"),
                    .init(name: "order", value: "display_order.asc"),
                ]
            )
        } catch CSSupabaseContentRepositoryError.invalidStatusCode {
            return try await request(
                path: "content_items",
                queryItems: [
                    .init(
                        name: "select",
                        value: "category_slug,subcategory_slug,slug,title,summary,blocks,related_item_ids,keywords,display_order"
                    ),
                    .init(name: "is_published", value: "eq.true"),
                    .init(name: "category_slug", value: "eq.\(categorySlug)"),
                    .init(name: "order", value: "display_order.asc"),
                ]
            )
        }
    }

    private func request<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]
    ) async throws -> T {
        guard let anonKey, !anonKey.isEmpty else {
            throw CSSupabaseContentRepositoryError.missingAnonKey
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw CSSupabaseContentRepositoryError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw CSSupabaseContentRepositoryError.invalidStatusCode(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw CSSupabaseContentRepositoryError.decodingFailed(error.localizedDescription)
        }
    }

    private static func prettyTitle(from slug: String) -> String {
        slug
            .split(separator: "-")
            .map { segment in
                let word = String(segment)
                if word.count <= 2 { return word.uppercased() }
                return word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }

    private static func normalizedTitle(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func parseBlocks(_ blocks: [JSONDictionary]) -> ParsedBlocks {
        var definitionBody: [String] = []
        var body: [String] = []
        var keyPoints: [String] = []
        var interviewPrompts: [String] = []
        var checkQuestions: [String] = []
        var imageURLs: [String] = []
        var imageURL: String?
        var imageAspectRatio: Double?
        var orderedBlocks: [CSStudyBlock] = []

        for block in blocks {
            let rawType = block["type"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let blockType = rawType.lowercased()
            if blockType.contains("image") {
                let candidates = extractImageURLs(from: block)
                if !candidates.isEmpty {
                    imageURLs = appendUnique(imageURLs, candidates)
                    if imageURL == nil {
                        imageURL = imageURLs.first
                    }
                    orderedBlocks.append(
                        CSStudyBlock(
                            type: rawType.isEmpty ? "image" : rawType,
                            items: candidates
                        )
                    )
                }
                if imageAspectRatio == nil {
                    if let explicitRatio = firstDouble(
                        forKeys: ["imageAspectRatio", "image_aspect_ratio", "aspectRatio", "aspect_ratio"],
                        in: block
                    ) {
                        imageAspectRatio = explicitRatio
                    } else if
                        let width = firstDouble(forKeys: ["width", "imageWidth", "image_width"], in: block),
                        let height = firstDouble(forKeys: ["height", "imageHeight", "image_height"], in: block),
                        height > 0 {
                        imageAspectRatio = width / height
                    }
                }
                continue
            }

            let textual = extractTextCandidates(from: block)
            if !textual.isEmpty {
                orderedBlocks.append(
                    CSStudyBlock(
                        type: rawType.isEmpty ? "text" : rawType,
                        items: textual
                    )
                )
            }

            if blockType.contains("definition") {
                definitionBody.append(contentsOf: textual)
            } else if blockType.contains("key") || blockType.contains("point") {
                keyPoints.append(contentsOf: textual)
            } else if blockType.contains("interview") {
                interviewPrompts.append(contentsOf: textual)
            } else if blockType.contains("check") || blockType.contains("question") || blockType.contains("quiz") {
                checkQuestions.append(contentsOf: textual)
            } else {
                body.append(contentsOf: textual)
            }

            if imageURL == nil {
                let candidates = extractImageURLs(from: block)
                if !candidates.isEmpty {
                    imageURLs = appendUnique(imageURLs, candidates)
                    imageURL = imageURLs.first
                }
                if let explicitRatio = firstDouble(
                    forKeys: ["imageAspectRatio", "image_aspect_ratio", "aspectRatio", "aspect_ratio"],
                    in: block
                ) {
                    imageAspectRatio = explicitRatio
                } else if
                    let width = firstDouble(forKeys: ["width", "imageWidth", "image_width"], in: block),
                    let height = firstDouble(forKeys: ["height", "imageHeight", "image_height"], in: block),
                    height > 0 {
                    imageAspectRatio = width / height
                }
            }
        }

        return ParsedBlocks(
            definitionBody: normalize(definitionBody),
            body: normalize(body),
            keyPoints: normalize(keyPoints),
            interviewPrompts: normalize(interviewPrompts),
            checkQuestions: normalize(checkQuestions),
            imageURLs: imageURLs,
            imageURL: imageURL,
            imageAspectRatio: imageAspectRatio,
            orderedBlocks: orderedBlocks
        )
    }

    private static func extractTextCandidates(from block: JSONDictionary) -> [String] {
        let directKeys = [
            "text", "content", "value", "description", "summary", "body"
        ]
        var values: [String] = []
        values.append(contentsOf: directKeys.compactMap { key in
            block[key]?.stringValue
        })

        let listKeys = [
            "items", "points", "prompts", "questions", "lines", "bullets"
        ]
        for key in listKeys {
            if let array = block[key]?.arrayValue {
                values.append(contentsOf: array.compactMap { $0.stringValue })
            }
        }

        // URL payloads should not be rendered as lesson body text.
        return values.filter { !isLikelyURLString($0) }
    }

    private static func extractImageURLs(from block: JSONDictionary) -> [String] {
        var urls: [String] = []

        if let direct = firstString(forKeys: ["imageUrl", "image_url", "url", "src"], in: block), !direct.isEmpty {
            urls.append(direct)
        }

        for key in ["items", "images", "urls"] {
            if let array = block[key]?.arrayValue {
                for value in array {
                    if let candidate = value.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !candidate.isEmpty,
                       isLikelyURLString(candidate) {
                        urls.append(candidate)
                    }
                }
            }
        }

        for key in ["image", "asset", "data", "payload"] {
            if let object = block[key]?.objectValue,
               let candidate = firstString(forKeys: ["imageUrl", "image_url", "url", "src"], in: object),
               !candidate.isEmpty {
                urls.append(candidate)
            }
        }

        return appendUnique([], urls)
    }

    private static func firstString(forKeys keys: [String], in block: JSONDictionary) -> String? {
        for key in keys {
            if let value = block[key]?.stringValue, !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private static func firstDouble(forKeys keys: [String], in block: JSONDictionary) -> Double? {
        for key in keys {
            if let value = block[key]?.doubleValue {
                return value
            }
        }
        return nil
    }

    private static func normalize(_ values: [String]) -> [String] {
        values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func isLikelyURLString(_ value: String) -> Bool {
        let lowered = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lowered.hasPrefix("http://") || lowered.hasPrefix("https://")
    }

    private static func appendUnique(_ current: [String], _ candidates: [String]) -> [String] {
        var result = current
        for candidate in candidates {
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if !result.contains(trimmed) {
                result.append(trimmed)
            }
        }
        return result
    }
}

public enum CSSupabaseContentRepositoryError: LocalizedError {
    case missingAnonKey
    case invalidURL
    case invalidStatusCode(Int)
    case decodingFailed(String)
    case categoryNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .missingAnonKey:
            return "SUPABASE_PUBLISHABLE_KEY(또는 SUPABASE_ANON_KEY)가 설정되지 않았습니다."
        case .invalidURL:
            return "Supabase 요청 URL 생성에 실패했습니다."
        case let .invalidStatusCode(code):
            return "Supabase content_items 요청 실패 (status: \(code))."
        case let .decodingFailed(message):
            return "content_items 디코딩 실패: \(message)"
        case let .categoryNotFound(slug):
            return "카테고리 데이터를 찾지 못했습니다: \(slug)"
        }
    }
}

private struct CategoryRow: Decodable {
    let categorySlug: String
    let categoryTitle: String?
    let displayOrder: Int
}

private struct ContentItemRow: Decodable {
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

private struct ParsedBlocks {
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

private typealias JSONDictionary = [String: JSONValue]

private enum JSONValue: Decodable {
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
