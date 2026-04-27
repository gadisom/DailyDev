import SwiftUI

public struct LearningCategoryVisualStyle: Equatable {
    public let canonicalID: String
    public let icon: String
    public let iconColorHex: String
    public let iconBackgroundHex: String
    public let sortOrder: Int

    public var iconColor: Color {
        Color(hexString: iconColorHex)
    }

    public var iconBackground: Color {
        Color(hexString: iconBackgroundHex)
    }

    public static let dataStructures = LearningCategoryVisualStyle(
        canonicalID: "data-structures",
        icon: "square.grid.3x3",
        iconColorHex: "#2B63EB",
        iconBackgroundHex: "#EFF7FF",
        sortOrder: 1
    )

    public static let algorithms = LearningCategoryVisualStyle(
        canonicalID: "algorithms",
        icon: "sum",
        iconColorHex: "#E08500",
        iconBackgroundHex: "#FFFAEB",
        sortOrder: 2
    )

    public static let operatingSystems = LearningCategoryVisualStyle(
        canonicalID: "operating-systems",
        icon: "terminal",
        iconColorHex: "#9442E8",
        iconBackgroundHex: "#FAF5FF",
        sortOrder: 3
    )

    public static let databases = LearningCategoryVisualStyle(
        canonicalID: "databases",
        icon: "cylinder",
        iconColorHex: "#0D9E6E",
        iconBackgroundHex: "#EDFCF5",
        sortOrder: 4
    )

    public static let networking = LearningCategoryVisualStyle(
        canonicalID: "networking",
        icon: "point.3.filled.connected.trianglepath.dotted",
        iconColorHex: "#ED215C",
        iconBackgroundHex: "#FFF2F5",
        sortOrder: 5
    )

    public static let objectOrientedProgramming = LearningCategoryVisualStyle(
        canonicalID: "oop",
        icon: "square.3.layers.3d",
        iconColorHex: "#F59E0B",
        iconBackgroundHex: "#FFFBEB",
        sortOrder: 6
    )

    public static let server = LearningCategoryVisualStyle(
        canonicalID: "server",
        icon: "server.rack",
        iconColorHex: "#0D9E6E",
        iconBackgroundHex: "#EFF7FF",
        sortOrder: 7
    )

    public static let iOS = LearningCategoryVisualStyle(
        canonicalID: "ios",
        icon: "iphone",
        iconColorHex: "#1C1C1E",
        iconBackgroundHex: "#F5F5F7",
        sortOrder: 8
    )

    public static let android = LearningCategoryVisualStyle(
        canonicalID: "android",
        icon: "hammer.fill",
        iconColorHex: "#3DDC84",
        iconBackgroundHex: "#F0FDF9",
        sortOrder: 9
    )

    public static let all: [LearningCategoryVisualStyle] = [
        dataStructures,
        algorithms,
        operatingSystems,
        databases,
        networking,
        objectOrientedProgramming,
        server,
        iOS,
        android,
    ]

    public static func style(for id: String, title: String? = nil) -> LearningCategoryVisualStyle? {
        var candidates = [id]
        if let title {
            candidates.append(title)
        }

        return candidates.lazy.compactMap { aliasMap[normalized($0)] }.first
    }

    public static func sortOrder(for id: String, title: String? = nil) -> Int {
        style(for: id, title: title)?.sortOrder ?? Int.max
    }

    private static let aliasMap: [String: LearningCategoryVisualStyle] = {
        var map: [String: LearningCategoryVisualStyle] = [:]

        func register(_ style: LearningCategoryVisualStyle, aliases: [String]) {
            for alias in aliases {
                map[normalized(alias)] = style
            }
        }

        register(dataStructures, aliases: [
            "data-structure",
            "data-structures",
            "datastructure",
            "datastructures",
            "자료구조",
        ])
        register(algorithms, aliases: [
            "algorithm",
            "algorithms",
            "algo",
            "알고리즘",
        ])
        register(operatingSystems, aliases: [
            "operating-system",
            "operating-systems",
            "operatingsystem",
            "operatingsystems",
            "운영체제",
        ])
        register(databases, aliases: [
            "database",
            "databases",
            "db",
            "데이터베이스",
        ])
        register(networking, aliases: [
            "network",
            "networking",
            "networks",
            "네트워크",
        ])
        register(objectOrientedProgramming, aliases: [
            "oop",
            "object-oriented-programming",
            "objectorientedprogramming",
            "객체지향",
        ])
        register(server, aliases: [
            "server",
            "backend",
            "back-end",
            "서버",
        ])
        register(iOS, aliases: [
            "ios",
            "iOS",
        ])
        register(android, aliases: [
            "android",
        ])

        return map
    }()

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}
