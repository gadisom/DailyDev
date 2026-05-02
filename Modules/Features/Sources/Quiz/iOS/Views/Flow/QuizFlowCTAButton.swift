#if os(iOS)
import SwiftUI
import DesignSystem

// MARK: - Shared helpers

enum QuizFlowCTAStyle { case dark, green, outline }

func quizFlowCTAButton(
    _ label: String,
    enabled: Bool,
    style: QuizFlowCTAStyle,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(style == .outline ? BrandPalette.ink : .white)
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(style == .outline ? BrandPalette.ink2 : .white)
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .background(
            style == .dark ? BrandPalette.ink
            : style == .green ? BrandPalette.green
            : BrandPalette.surface
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            style == .outline
            ? RoundedRectangle(cornerRadius: 14).stroke(BrandPalette.line, lineWidth: 1)
            : nil
        )
        .opacity(enabled ? 1 : 0.4)
    }
    .buttonStyle(ScaleButtonStyle())
    .disabled(!enabled)
}
#endif
