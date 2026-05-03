import Core
import DesignSystem
import SwiftUI

struct ForceUpdateView: View {
    let policy: AppUpdatePolicy

    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            BrandPalette.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("DAILYDEV")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(1.8)
                    .foregroundStyle(BrandPalette.green)
                    .textCase(.uppercase)

                Text("업데이트가 필요합니다")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(BrandPalette.ink)
                    .padding(.top, 18)

                Text(policy.message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(BrandPalette.ink2)
                    .lineSpacing(5)
                    .padding(.top, 14)

                VStack(alignment: .leading, spacing: 8) {
                    versionRow(title: "현재 버전", value: policy.currentVersion)
                    versionRow(title: "최소 지원 버전", value: policy.minimumVersion)
                }
                .padding(18)
                .background(BrandPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(BrandPalette.line, lineWidth: 1)
                )
                .padding(.top, 28)

                Button {
                    if let updateURL = policy.updateURL {
                        openURL(updateURL)
                    }
                } label: {
                    HStack {
                        Text("App Store에서 업데이트")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 56)
                    .background(BrandPalette.green)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 28)
            }
            .padding(28)
            .frame(maxWidth: 520, alignment: .leading)
        }
    }

    private func versionRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BrandPalette.ink3)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(BrandPalette.ink)
        }
    }
}
