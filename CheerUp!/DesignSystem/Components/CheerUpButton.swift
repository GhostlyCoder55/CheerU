import SwiftUI

// MARK: - Reusable Button Styles

struct CheerUpPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(CheerUpFont.headline)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(CheerUpColors.lightGrey)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.buttonCornerRadius, style: .continuous))
        }
        .accessibilityLabel(title)
    }
}

struct CheerUpSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(CheerUpFont.headline)
            }
            .foregroundStyle(CheerUpColors.lightGrey)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(CheerUpColors.blueGrey.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.buttonCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.buttonCornerRadius, style: .continuous)
                    .stroke(CheerUpColors.slate.opacity(0.4), lineWidth: 1)
            )
        }
        .accessibilityLabel(title)
    }
}

// MARK: - Pressable Button Style

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
