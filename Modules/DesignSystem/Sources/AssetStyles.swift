import SwiftUI

// MARK: - Shadow Tokens

public extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color(red: 0.11, green: 0.10, blue: 0.09).opacity(0.04), radius: 1, x: 0, y: 1)
            .shadow(color: Color(red: 0.11, green: 0.10, blue: 0.09).opacity(0.04), radius: 8, x: 0, y: 2)
    }

    func popShadow() -> some View {
        self.shadow(color: Color(red: 0.11, green: 0.10, blue: 0.09).opacity(0.10), radius: 24, x: 0, y: 8)
    }
}

// MARK: - Card Surface Modifier

public struct CardSurface: ViewModifier {
    public var radius: CGFloat
    public var padding: CGFloat

    public init(radius: CGFloat = 16, padding: CGFloat = 16) {
        self.radius = radius
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(BrandPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(BrandPalette.line, lineWidth: 1)
            )
            .cardShadow()
    }
}

public extension View {
    func cardSurface(radius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        modifier(CardSurface(radius: radius, padding: padding))
    }
}

// MARK: - Chip

public enum ChipTone {
    case neutral, green, banana, outline, danger
}

public struct DailyDevChip: View {
    private let text: String
    private let tone: ChipTone
    private let size: ChipSize

    public enum ChipSize { case sm, md }

    public init(_ text: String, tone: ChipTone = .neutral, size: ChipSize = .md) {
        self.text = text
        self.tone = tone
        self.size = size
    }

    private var foreground: Color {
        switch tone {
        case .neutral:  return BrandPalette.ink2
        case .green:    return BrandPalette.greenInk
        case .banana:   return Color(red: 0.478, green: 0.353, blue: 0.063)
        case .outline:  return BrandPalette.ink2
        case .danger:   return BrandPalette.danger
        }
    }

    private var background: Color {
        switch tone {
        case .neutral:  return BrandPalette.surfaceAlt
        case .green:    return BrandPalette.greenSoft
        case .banana:   return BrandPalette.bananaSoft
        case .outline:  return .clear
        case .danger:   return BrandPalette.dangerSoft
        }
    }

    private var border: Color? {
        tone == .outline ? BrandPalette.line : nil
    }

    private var height: CGFloat { size == .sm ? 22 : 26 }
    private var hPad: CGFloat   { size == .sm ?  8 : 10 }
    private var fontSize: CGFloat { size == .sm ? 11 : 12 }

    public var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, hPad)
            .frame(height: height)
            .background(background)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(border ?? .clear, lineWidth: border != nil ? 1 : 0)
            )
    }
}

// MARK: - Section Label

public struct DailyDevSectionLabel: View {
    private let text: String
    private let trailing: AnyView?

    public init(_ text: String) {
        self.text = text
        self.trailing = nil
    }

    public init<T: View>(_ text: String, @ViewBuilder trailing: () -> T) {
        self.text = text
        self.trailing = AnyView(trailing())
    }

    public var body: some View {
        HStack {
            Text(text)
                .font(DailyDevTypography.labelSmall)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(BrandPalette.ink3)
            Spacer()
            trailing
        }
    }
}

// MARK: - Section Title (legacy — kept for compat)

public struct DailyDevSectionTitle: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(DailyDevTypography.labelSmall)
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(BrandPalette.ink3)
    }
}

// MARK: - Tag Chip (legacy — kept for compat)

public struct DailyDevTagChip: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        DailyDevChip(text, tone: .green, size: .sm)
    }
}

// MARK: - Primary Button

public struct DailyDevPrimaryButton: View {
    private let label: String
    private let action: () -> Void

    public init(_ label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(BrandPalette.green)
                .clipShape(RoundedRectangle(cornerRadius: Radius.button))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale tap animation

public struct ScaleButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DailyDevAnimation.tapScale : 1)
            .animation(DailyDevAnimation.snappy, value: configuration.isPressed)
    }
}

// MARK: - Icon Box

public struct DailyDevIconBox: View {
    private let systemName: String
    private let size: CGFloat
    private let iconSize: CGFloat
    private let background: Color
    private let foreground: Color

    public init(
        systemName: String,
        size: CGFloat = 46,
        iconSize: CGFloat = 22,
        background: Color = BrandPalette.surfaceAlt,
        foreground: Color = BrandPalette.ink2
    ) {
        self.systemName = systemName
        self.size = size
        self.iconSize = iconSize
        self.background = background
        self.foreground = foreground
    }

    public var body: some View {
        Image(systemName: systemName)
            .font(.system(size: iconSize, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}
