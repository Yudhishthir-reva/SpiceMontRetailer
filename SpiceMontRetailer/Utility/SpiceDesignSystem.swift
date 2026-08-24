//
//  SpiceDesignSystem.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI

// MARK: - Spice Buttons

struct SpicePrimaryButton: View {
    let title: String
    var icon: String? = nil
    var height: CGFloat = 52
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: height > 40 ? 15 : 12, weight: .bold))
                }
                Text(title)
                    .font(.system(size: height > 40 ? 14.5 : 12, weight: .heavy))
                    .tracking(0.2)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(isEnabled ? Color.spicePrimary : Color.spiceMuted.opacity(0.4))
            .cornerRadius(height > 40 ? 13 : 10)
        }
        .disabled(!isEnabled)
    }
}

struct SpiceOutlinedButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .spicePrimary
    var height: CGFloat = 52
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: height > 40 ? 14 : 11, weight: .bold))
                }
                Text(title)
                    .font(.system(size: height > 40 ? 14 : 12, weight: .heavy))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: height > 40 ? 13 : 10)
                    .stroke(color, lineWidth: 1.5)
            )
            .cornerRadius(height > 40 ? 13 : 10)
        }
    }
}

struct SpiceGhostButton: View {
    let title: String
    var icon: String? = nil
    var height: CGFloat = 38
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(Color.spiceInk)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.spiceCardBorder, lineWidth: 1)
            )
            .cornerRadius(10)
        }
    }
}

// MARK: - Spice Card Container

struct SpiceCard<Content: View>: View {
    var backgroundColor: Color = .white
    var borderColor: Color = Color.spiceCardBorder
    var padding: CGFloat = 14
    var cornerRadius: CGFloat = 16
    let content: Content

    init(
        backgroundColor: Color = .white,
        borderColor: Color = Color.spiceCardBorder,
        padding: CGFloat = 14,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}

// MARK: - Status Badge

struct SpiceStatusBadge: View {
    let status: String

    private var badgeColor: (bg: Color, text: Color) {
        let upper = status.uppercased().replacingOccurrences(of: "_", with: " ")
        switch upper {
        case "APPROVED", "DELIVERED", "CONFIRMED", "VERIFIED", "UPLOADED", "ACTIVE":
            return (Color.spicePrimaryLight, Color.spicePrimary)
        case "OUT FOR DELIVERY", "ORDER VALUE SLAB", "DISPATCHED", "PROCESSING":
            return (Color.spiceTransitLight, Color.spiceTransit)
        case "PENDING REVIEW", "PENDING_REVIEW", "LOW STOCK", "RETAILER SPECIFIC":
            return (Color.spiceAmberLight, Color.spiceAmber)
        case "REJECTED", "BLOCKED", "CANCELLED", "OUT OF STOCK":
            return (Color.spiceDueLight, Color.spiceDue)
        default:
            return (Color.spiceLightGray, Color.spiceMuted)
        }
    }

    var body: some View {
        Text(status.uppercased().replacingOccurrences(of: "_", with: " "))
            .font(.system(size: 10, weight: .bold))
            .tracking(0.3)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.bg)
            .foregroundColor(badgeColor.text)
            .cornerRadius(6)
    }
}

// MARK: - Top Navigation Bar

struct SpiceTopBar: View {
    let title: String
    var subtitle: String? = nil
    var showBack: Bool = true
    var onBack: (() -> Void)? = nil
    var trailingItem: AnyView? = nil

    var body: some View {
        HStack(spacing: 12) {
            if showBack {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                        .frame(width: 32, height: 32)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Color.spiceInk)
                    .lineLimit(1)
                
                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let trailingItem = trailingItem {
                trailingItem
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(
            Divider().background(Color.spiceDivider),
            alignment: .bottom
        )
    }
}

// MARK: - Monospace Currency & Code Text

struct SpiceMonoText: View {
    let text: String
    var size: CGFloat = 13
    var weight: Font.Weight = .semibold
    var color: Color = Color.spiceInk

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: weight, design: .monospaced))
            .foregroundColor(color)
    }
}

// MARK: - Key-Value Row

struct SpiceKVRow: View {
    let key: String
    let value: String
    var isMonoValue: Bool = false
    var valueColor: Color = Color.spiceInk

    var body: some View {
        HStack {
            Text(key)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.spiceMuted)
            Spacer()
            if isMonoValue {
                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(valueColor)
            } else {
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(valueColor)
            }
        }
    }
}

// MARK: - Skeleton Shimmer

struct SpiceSkeletonBox: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 6

    @State private var isAnimating: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.spiceLightGray)
            .frame(height: height)
            .frame(maxWidth: width ?? .infinity)
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Empty & Error State Views

struct SpiceEmptyStateView: View {
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        SpiceCard(backgroundColor: .white, borderColor: Color.spiceCardBorder.opacity(0.8)) {
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 13.5, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Text(message)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
                    .multilineTextAlignment(.center)

                if let btn = buttonTitle, let onAction = onAction {
                    Button(action: onAction) {
                        Text(btn)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(Color.spicePrimary)
                            .cornerRadius(10)
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
}
