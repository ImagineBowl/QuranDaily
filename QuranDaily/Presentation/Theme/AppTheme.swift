import SwiftUI

enum AppTheme {
    static let minimumTapSize: CGFloat = 48
    static let cardCornerRadius: CGFloat = 16
    static let sectionSpacing: CGFloat = 20

    static func arabicFont(size: Double) -> Font {
        .system(size: size + 6, weight: .regular, design: .serif)
    }

    static func bodyFont(size: Double) -> Font {
        .system(size: size, weight: .regular)
    }

    static func titleFont(size: Double) -> Font {
        .system(size: size + 4, weight: .semibold)
    }

    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let accent = Color(red: 0.12, green: 0.45, blue: 0.35)
}

struct LargeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTapSize)
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTapSize)
            .background(AppTheme.secondaryBackground.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
}
