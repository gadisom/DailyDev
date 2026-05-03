public enum AppVersionComparator {
    public static func isVersion(_ currentVersion: String, lowerThan minimumVersion: String) -> Bool {
        let currentParts = numericParts(from: currentVersion)
        let minimumParts = numericParts(from: minimumVersion)
        let count = max(currentParts.count, minimumParts.count)

        for index in 0..<count {
            let current = index < currentParts.count ? currentParts[index] : 0
            let minimum = index < minimumParts.count ? minimumParts[index] : 0

            if current != minimum {
                return current < minimum
            }
        }

        return false
    }

    private static func numericParts(from version: String) -> [Int] {
        version
            .split(separator: ".")
            .map { Int($0) ?? 0 }
    }
}
