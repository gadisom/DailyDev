import Entity
import Foundation
import Domain

public actor CSSupabaseContentRepository: CSContentRepository {
    private let client: SupabaseRequesting

    public init(
        client: SupabaseRequesting = SupabaseClient()
    ) {
        self.client = client
    }

    public func fetchCategories() async throws -> [CSCategoryDefinition] {
        let rows = try await fetchLearningCategoryRows()

        return rows
            .map { row in
                let categorySlug = Self.contentCategorySlug(for: row.id)
                return CSCategoryDefinition(
                    id: categorySlug,
                    title: Self.normalizedTitle(row.name) ?? Self.prettyTitle(from: categorySlug),
                    displayOrder: Self.categoryDisplayOrder(for: row.id)
                )
            }
            .sorted {
                if $0.displayOrder != $1.displayOrder { return $0.displayOrder < $1.displayOrder }
                return $0.title.localizedCompare($1.title) == .orderedAscending
            }
    }

    public func fetchCategoryContent(categorySlug: String) async throws -> CSCategoryContent {
        let result = try await fetchMatchingContentRows(categorySlug: categorySlug)
        let rows = result.rows

        guard !rows.isEmpty else {
            throw CSSupabaseContentRepositoryError.categoryNotFound(categorySlug)
        }

        let categoryTitle = rows
            .compactMap { Self.normalizedTitle($0.categoryTitle) }
            .first ?? Self.prettyTitle(from: categorySlug)

        var grouped: [String: [CSContentItemDTO]] = [:]
        var subcategoryOrder: [String: Int] = [:]
        var subcategoryTitles: [String: String] = [:]

        for row in rows {
            grouped[row.slug, default: []].append(row)
            let existing = subcategoryOrder[row.slug]
            subcategoryOrder[row.slug] = min(existing ?? row.displayOrder, row.displayOrder)
            if let title = Self.normalizedTitle(row.subcategoryTitle), subcategoryTitles[row.slug] == nil {
                subcategoryTitles[row.slug] = title
            }
        }

        let subcategories = grouped
            .map { subcategorySlug, itemRows -> CSSubcategory in
                let sortedRows = itemRows.sorted { lhs, rhs in
                    if lhs.displayOrder != rhs.displayOrder {
                        return lhs.displayOrder < rhs.displayOrder
                    }
                    return (lhs.subcategoryTitle ?? "").localizedCompare(rhs.subcategoryTitle ?? "") == .orderedAscending
                }

                let items = sortedRows.enumerated().map { index, row -> CSStudyItem in
                    let parsed = Self.parseBlocks(row.blocks)
                    let summary = row.summary?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let fallbackSummary = parsed.definitionBody.first ?? parsed.body.first ?? row.subcategoryTitle ?? ""

                    return CSStudyItem(
                        id: row.slug,
                        title: row.subcategoryTitle ?? Self.prettyTitle(from: row.slug),
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

    private func fetchLearningCategoryRows() async throws -> [CSLearningCategoryDTO] {
        try await request(
            path: "quiz_categories",
            queryItems: [
                .init(name: "select", value: "id,name"),
                .init(name: "order", value: "id.asc"),
            ]
        )
    }

    private func fetchMatchingContentRows(categorySlug: String) async throws -> (slug: String, rows: [CSContentItemDTO]) {
        for candidate in Self.contentSlugCandidates(for: categorySlug) {
            let rows = try await fetchContentRows(categorySlug: candidate)
            if !rows.isEmpty {
                return (slug: candidate, rows: rows)
            }
        }

        return (slug: categorySlug, rows: [])
    }

    private func fetchContentRows(categorySlug: String) async throws -> [CSContentItemDTO] {
        do {
            return try await request(
                path: "content_items",
                queryItems: [
                    .init(
                        name: "select",
                        value: "category_slug,category_title,subcategory_title,slug,summary,blocks,related_item_ids,keywords,display_order"
                    ),
                    .init(name: "is_published", value: "eq.true"),
                    .init(name: "category_slug", value: "eq.\(categorySlug)"),
                    .init(name: "order", value: "display_order.asc"),
                ]
            )
        } catch let error as SupabaseClientError {
            guard case .invalidStatusCode = error else {
                throw mapRequestError(error)
            }
            return try await request(
                path: "content_items",
                queryItems: [
                    .init(
                        name: "select",
                        value: "category_slug,slug,summary,blocks,related_item_ids,keywords,display_order"
                    ),
                    .init(name: "is_published", value: "eq.true"),
                    .init(name: "category_slug", value: "eq.\(categorySlug)"),
                    .init(name: "order", value: "display_order.asc"),
                ]
            )
        }
    }

    private func request<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        do {
            return try await client.request(path: path, queryItems: queryItems)
        } catch {
            throw mapRequestError(error)
        }
    }

    private func mapRequestError(_ error: Error) -> Error {
        if let error = error as? SupabaseClientError {
            switch error {
            case .missingAnonKey:
                return CSSupabaseContentRepositoryError.missingAnonKey
            case .invalidURL:
                return CSSupabaseContentRepositoryError.invalidURL
            case .invalidStatusCode(let code):
                return CSSupabaseContentRepositoryError.invalidStatusCode(code)
            case .invalidResponse:
                return CSSupabaseContentRepositoryError.decodingFailed("유효하지 않은 응답입니다.")
            case .decodingFailed(let message):
                return CSSupabaseContentRepositoryError.decodingFailed(message)
            }
        }
        return error
    }

    private static func contentCategorySlug(for quizCategoryID: String) -> String {
        switch normalizedSlug(quizCategoryID) {
        case "datastructures":
            return "data-structure"
        case "operatingsystems":
            return "operating-system"
        case "databases":
            return "database"
        case "networking":
            return "network"
        default:
            return quizCategoryID
        }
    }

    private static func categoryDisplayOrder(for categoryID: String) -> Int {
        switch normalizedSlug(categoryID) {
        case "datastructure", "datastructures":
            return 1
        case "algorithm", "algorithms":
            return 2
        case "operatingsystem", "operatingsystems":
            return 3
        case "database", "databases":
            return 4
        case "network", "networking":
            return 5
        case "oop":
            return 6
        case "server":
            return 7
        case "ios":
            return 8
        case "android":
            return 9
        default:
            return 99
        }
    }

    private static func contentSlugCandidates(for categorySlug: String) -> [String] {
        let normalized = normalizedSlug(categorySlug)
        let aliases: [String]

        switch normalized {
        case "datastructure", "datastructures":
            aliases = ["data-structure", "data-structures"]
        case "operatingsystem", "operatingsystems":
            aliases = ["operating-system", "operating-systems"]
        case "database", "databases":
            aliases = ["database", "databases"]
        case "network", "networking":
            aliases = ["network", "networking"]
        default:
            aliases = [categorySlug]
        }

        return ([categorySlug] + aliases).reduce(into: []) { result, slug in
            if !result.contains(slug) {
                result.append(slug)
            }
        }
    }

    private static func normalizedSlug(_ slug: String) -> String {
        slug
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
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
