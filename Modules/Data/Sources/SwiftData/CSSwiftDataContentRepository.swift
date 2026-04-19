import Domain
import Entity
import Foundation
import SwiftData

public actor CSContentRepository: CSResourceRepository {
    private let context: ModelContext
    private let container: ModelContainer
    private let remoteService: CSRemoteContentService
    private let bundleRepository: CSBundleRepository
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        container: ModelContainer? = nil,
        remoteService: CSRemoteContentService = CSRemoteContentService(),
        bundleRepository: CSBundleRepository = CSBundleRepository(),
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        let resolvedContainer = container ?? Self.makeContainer()
        self.container = resolvedContainer
        self.context = ModelContext(resolvedContainer)
        self.remoteService = remoteService
        self.bundleRepository = bundleRepository
        self.decoder = decoder
        self.encoder = encoder
    }

    public func syncIfNeeded(forceRefresh: Bool = false) async throws -> CSContentManifest {
        if !forceRefresh, let localManifest = try? await fetchManifest() {
            do {
                let remoteManifest = try await remoteService.fetchManifest()

                if remoteManifest.version > localManifest.version {
                    let remoteIndex = try await remoteService.fetchCategories()
                    try await replaceSnapshot(
                        manifest: remoteManifest,
                        index: remoteIndex
                    )
                    return remoteManifest
                }

                return localManifest
            } catch {
                return localManifest
            }
        }

        do {
            let remoteManifest = try await remoteService.fetchManifest()
            let remoteIndex = try await remoteService.fetchCategories()
            try await replaceSnapshot(
                manifest: remoteManifest,
                index: remoteIndex
            )
            return remoteManifest
        } catch {
            if let manifest = try? await bootstrapFromBundle() {
                return manifest
            }
            throw CSContentRepositoryError.noLocalDataAvailable
        }
    }

    public func fetchManifest() async throws -> CSContentManifest {
        let descriptor = FetchDescriptor<CSContentManifestRecord>(
            predicate: #Predicate { $0.id == "current" }
        )

        guard let record = try context.fetch(descriptor).first else {
            throw CSContentRepositoryError.manifestNotFound
        }

        return CSContentManifest(
            version: record.version,
            updatedAt: record.updatedAt,
            files: record.fileList
        )
    }

    public func fetchCategories() async throws -> [CSCategoryDefinition] {
        let descriptor = FetchDescriptor<CSCategoryRecord>(
            sortBy: [
                SortDescriptor(\.displayOrder),
                SortDescriptor(\.title)
            ]
        )

        let records = try context.fetch(descriptor)
        return records.map {
            CSCategoryDefinition(
                id: $0.id,
                title: $0.title,
                displayOrder: $0.displayOrder,
                devFile: $0.devFile,
                prodFile: $0.prodFile
            )
        }
    }

    public func fetchCategoryContent(prodFile: String) async throws -> CSCategoryContent {
        let descriptor = FetchDescriptor<CSCategoryContentRecord>(
            predicate: #Predicate { $0.prodFile == prodFile }
        )

        guard let record = try context.fetch(descriptor).first else {
            throw CSContentRepositoryError.contentNotFound(prodFile)
        }

        do {
            return try decoder.decode(CSCategoryContent.self, from: record.payload)
        } catch {
            throw CSContentRepositoryError.decodingFailed(prodFile: prodFile, underlying: error)
        }
    }

    private func replaceSnapshot(manifest: CSContentManifest, index: CSCategoriesIndex) async throws {
        let categories = index.categories

        try clearCache()
        try persistManifest(manifest, files: categories.map(\.prodFile))

        for category in categories {
            let categoryRecord = CSCategoryRecord(
                id: category.id,
                title: category.title,
                displayOrder: category.displayOrder,
                devFile: category.devFile,
                prodFile: category.prodFile
            )
            context.insert(categoryRecord)

            let content = try await remoteService.fetchCategoryContent(prodFile: category.prodFile)
            let encodedContent = try encoder.encode(content)
            let contentRecord = CSCategoryContentRecord(
                prodFile: category.prodFile,
                title: content.title,
                displayOrder: content.displayOrder,
                payload: encodedContent,
                category: categoryRecord
            )
            context.insert(contentRecord)
            categoryRecord.contents.append(contentRecord)
        }

        try context.save()
    }

    private func bootstrapFromBundle() async throws -> CSContentManifest {
        let index = try bundleRepository.fetchCategories()
        let products: [CSCategoryDefinition] = index.categories

        try clearCache()
        persistManifest(
            CSContentManifest(
                version: index.version,
                updatedAt: Self.currentTimeString(),
                files: products.map(\.prodFile)
            ),
            files: products.map(\.prodFile)
        )

        for category in products {
            let categoryRecord = CSCategoryRecord(
                id: category.id,
                title: category.title,
                displayOrder: category.displayOrder,
                devFile: category.devFile,
                prodFile: category.prodFile
            )
            context.insert(categoryRecord)

            let content = try bundleRepository.fetchCategoryContent(prodFile: category.prodFile)
            let encodedContent = try encoder.encode(content)
            let contentRecord = CSCategoryContentRecord(
                prodFile: category.prodFile,
                title: content.title,
                displayOrder: content.displayOrder,
                payload: encodedContent,
                category: categoryRecord
            )
            context.insert(contentRecord)
            categoryRecord.contents.append(contentRecord)
        }

        try context.save()

        return try await fetchManifest()
    }

    private func clearCache() throws {
        let manifests = try context.fetch(FetchDescriptor<CSContentManifestRecord>())
        for manifest in manifests {
            context.delete(manifest)
        }

        let contents = try context.fetch(FetchDescriptor<CSCategoryContentRecord>())
        for content in contents {
            context.delete(content)
        }

        let categories = try context.fetch(FetchDescriptor<CSCategoryRecord>())
        for category in categories {
            context.delete(category)
        }
    }

    private func persistManifest(_ manifest: CSContentManifest, files: [String]) {
        let record = CSContentManifestRecord(
            version: manifest.version,
            updatedAt: manifest.updatedAt,
            files: files
        )
        context.insert(record)
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            CSContentManifestRecord.self,
            CSCategoryRecord.self,
            CSCategoryContentRecord.self
        ])

        do {
            let config = ModelConfiguration("DailyDevCS")
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            return try! ModelContainer(
                for: schema,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
    }

    private static func currentTimeString() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: Date())
    }
}

public enum CSContentRepositoryError: LocalizedError {
    case noLocalDataAvailable
    case manifestNotFound
    case contentNotFound(String)
    case decodingFailed(prodFile: String, underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .noLocalDataAvailable:
            return "로컬에 CS 데이터가 없습니다."
        case .manifestNotFound:
            return "로컬 CS 매니페스트를 찾을 수 없습니다."
        case let .contentNotFound(prodFile):
            return "카테고리 콘텐츠를 찾을 수 없습니다: \(prodFile)"
        case let .decodingFailed(prodFile, underlying):
            return "콘텐츠 디코딩 실패(\(prodFile)): \(underlying.localizedDescription)"
        }
    }
}
