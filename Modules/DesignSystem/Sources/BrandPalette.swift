import SwiftUI

// MARK: - Color Tokens

public enum BrandPalette {
    // MARK: Shared neutrals
    public static let surfaceWhite  = Color.white
    public static let surfaceBorder = Color.black.opacity(0.05)

    // MARK: Content colors
    public static let textHighContrast = ink
    public static let textStandard = ink2
    public static let textLowContrast = ink3
    public static let textMuted = Color(red: 0.36, green: 0.37, blue: 0.39)
    public static let textDimmed = Color(red: 0.26, green: 0.28, blue: 0.33)
    public static let textDisabled = ink4
    public static let iconMuted = Color(red: 0.39, green: 0.45, blue: 0.55)
    public static let iconDimmed = Color(red: 0.38, green: 0.44, blue: 0.53)
    public static let textSubtle = Color(red: 0.28, green: 0.34, blue: 0.41)
    public static let textSecondaryBody = Color(red: 0.24, green: 0.30, blue: 0.38)
    public static let textSecondaryStrong = Color(red: 0.12, green: 0.16, blue: 0.23)
    public static let textHint = Color(red: 0.58, green: 0.64, blue: 0.72)

    // MARK: Surfaces
    public static let surfaceSoft = Color(red: 0.97, green: 0.98, blue: 0.99)
    public static let surfaceVerySoft = Color(red: 0.91, green: 0.91, blue: 0.93)
    public static let surfaceOutline = Color(red: 0.89, green: 0.91, blue: 0.94)
    public static let surfaceMuted = Color(red: 0.95, green: 0.96, blue: 0.98)

    // MARK: Interaction
    public static let tint = Color(red: 0.0, green: 0.35, blue: 0.74)
    public static let progressTint = Color(red: 0.0, green: 0.35, blue: 0.74)

    // MARK: Backgrounds
    public static let background   = Color(red: 0.969, green: 0.961, blue: 0.941) // #F7F5F0 warm paper
    public static let surface      = Color.white                                   // #FFFFFF cards
    public static let surfaceAlt   = Color(red: 0.945, green: 0.933, blue: 0.906) // #F1EEE7 sunk / chips

    // MARK: Borders
    public static let line         = Color(red: 0.902, green: 0.882, blue: 0.839) // #E6E1D6 dividers
    public static let lineStrong   = Color(red: 0.847, green: 0.820, blue: 0.761) // #D8D1C2

    // MARK: Ink (text hierarchy)
    public static let ink          = Color(red: 0.110, green: 0.102, blue: 0.086) // #1C1A16 primary
    public static let ink2         = Color(red: 0.227, green: 0.208, blue: 0.188) // #3A3530 secondary
    public static let ink3         = Color(red: 0.455, green: 0.431, blue: 0.400) // #746E66 tertiary / captions
    public static let ink4         = Color(red: 0.702, green: 0.678, blue: 0.639) // #B3ADA3 hairlines

    // MARK: Brand green (primary accent)
    public static let green        = Color(red: 0.184, green: 0.365, blue: 0.275) // #2F5D46
    public static let greenHi      = Color(red: 0.243, green: 0.439, blue: 0.345) // #3E7058 hover
    public static let greenSoft    = Color(red: 0.906, green: 0.937, blue: 0.914) // #E7EFE9 tinted surface
    public static let greenInk     = Color(red: 0.118, green: 0.239, blue: 0.180) // #1E3D2E text on soft

    // MARK: Banana (logo highlight — use sparingly)
    public static let banana       = Color(red: 0.910, green: 0.722, blue: 0.290) // #E8B84A
    public static let bananaSoft   = Color(red: 0.988, green: 0.945, blue: 0.831) // #FCF1D4

    // MARK: Semantic
    public static let danger       = Color(red: 0.722, green: 0.290, blue: 0.243) // #B84A3E
    public static let dangerSoft   = Color(red: 0.961, green: 0.886, blue: 0.875) // #F5E2DF

    // MARK: Curriculum style chips
    public static let curriculumBlueBackground = Color(red: 0.94, green: 0.97, blue: 1.0)
    public static let curriculumBlueText = Color(red: 0.17, green: 0.39, blue: 0.92)
    public static let curriculumOrangeBackground = Color(red: 1.0, green: 0.98, blue: 0.92)
    public static let curriculumOrangeText = Color(red: 0.88, green: 0.52, blue: 0.0)
    public static let curriculumPurpleBackground = Color(red: 0.98, green: 0.96, blue: 1.0)
    public static let curriculumPurpleText = Color(red: 0.58, green: 0.26, blue: 0.91)
    public static let curriculumGreenBackground = Color(red: 0.93, green: 0.99, blue: 0.96)
    public static let curriculumGreenText = Color(red: 0.05, green: 0.62, blue: 0.43)
    public static let curriculumRedBackground = Color(red: 1.0, green: 0.95, blue: 0.96)
    public static let curriculumRedText = Color(red: 0.93, green: 0.13, blue: 0.36)

    // MARK: Legacy aliases (kept for backward compat)
    public static let accent       = green
    public static let interactiveTint = tint
    public static let card         = surface
    public static let textPrimary  = ink
    public static let textSecondary = ink3
}

// MARK: - Typography Tokens

public enum DailyDevTypography {
    // Display — hero titles
    public static let display      = Font.system(size: 38, weight: .bold)
    public static let displayRoundedLarge = Font.system(size: 50, weight: .bold, design: .rounded)
    // Title levels
    public static let title1       = Font.system(size: 34, weight: .bold)
    public static let title2       = Font.system(size: 30, weight: .bold)
    public static let title3       = Font.system(size: 22, weight: .bold)
    public static let title20      = Font.system(size: 20, weight: .bold)
    public static let title16      = Font.system(size: 16, weight: .bold)
    // Body
    public static let bodyLarge    = Font.system(size: 17, weight: .medium)
    public static let body         = Font.system(size: 15, weight: .regular)
    public static let body16      = Font.system(size: 16, weight: .regular)
    public static let bodySmall    = Font.system(size: 14, weight: .regular)
    public static let bodySmallRegular = Font.system(size: 13, weight: .regular)
    // UI labels
    public static let label        = Font.system(size: 13, weight: .semibold)
    public static let labelSmall   = Font.system(size: 11, weight: .semibold)
    public static let caption      = Font.system(size: 10, weight: .medium)
    public static let captionBold  = Font.system(size: 10, weight: .bold)
    // Mono — for stats, tags, badges
    public static let mono         = Font.system(size: 13, weight: .semibold, design: .monospaced)
    public static let monoSmall    = Font.system(size: 11, weight: .semibold, design: .monospaced)
    public static let monoCaption  = Font.system(size: 10, weight: .medium, design: .monospaced)
    public static let monoBold12   = Font.system(size: 12, weight: .bold, design: .monospaced)
    public static let monoLabel10  = Font.system(size: 10, weight: .semibold, design: .monospaced)
    public static let captionSemibold = Font.system(size: 13, weight: .semibold)
}

// MARK: - Legacy Font extensions (kept for backward compat)

public extension Font {
    static let dailyDevTitle    = DailyDevTypography.title1
    static let dailyDevHeadline = DailyDevTypography.title3
    static let dailyDevBody     = DailyDevTypography.body
}
