//
//  AppTheme.swift
//  SpiceMonk
//

import SwiftUI

enum AppTheme {
    // ── Action ──────────────────────────────────────────────────────────────────
    static let brandGreen = Color(hex: "#0E8A4C")
    static let brandGreenLight = Color(hex: "#E7F3EC")
    static let brandGreenDark = Color(hex: "#0A6B3B")
    static let brandGreenBorder = Color(hex: "#B6DCC6")

    // ── Ink ─────────────────────────────────────────────────────────────────────
    static let textPrimary = Color(hex: "#0E1418")
    static let textSecondary = Color(hex: "#3A423B")
    static let textMuted = Color(hex: "#69716A")
    static let textFaint = Color(hex: "#9AA39B")

    // ── Surfaces ────────────────────────────────────────────────────────────────
    static let surfaceWhite = Color(hex: "#FFFFFF")
    static let surfaceWash = Color(hex: "#F6F7F5")
    static let surfaceSunken = Color(hex: "#EEF0EC")

    // ── Lines ───────────────────────────────────────────────────────────────────
    static let cardBorder = Color(hex: "#E5E8E2")
    static let fieldBorder = Color(hex: "#DDE1DA")
    static let chipBorder = Color(hex: "#E1E5DE")
    static let hairline = Color(hex: "#EEF0EC")

    // ── Semantic ────────────────────────────────────────────────────────────────
    static let transit = Color(hex: "#1B57D6")
    static let transitWash = Color(hex: "#E8EEFB")

    static let due = Color(hex: "#C8322B")
    static let dueWash = Color(hex: "#FBE3E1")
    static let dueBorder = Color(hex: "#F0CFCC")

    static let pending = Color(hex: "#A85B08")
    static let pendingWash = Color(hex: "#FDF0DC")
    static let pendingBorder = Color(hex: "#F0DEC2")

    static let settled = Color(hex: "#0AB39C")
    static let settledWash = Color(hex: "#E3F6F3")

    static let neutral = Color(hex: "#59615A")
    static let neutralWash = Color(hex: "#EEF0EC")

    // ── Legacy Aliases ──────────────────────────────────────────────────────────
    static let brandBackgroundTop = surfaceWash
    static let brandBackgroundMid = surfaceWash
    static let brandBackgroundBottom = surfaceSunken
    static let brandRed = due
    static let brandRedDark = Color(hex: "#8B1E19")
    static let ctaGradient = LinearGradient(
        colors: [Color(hex: "#0E8A4C"), Color(hex: "#0A6B3B")],
        startPoint: .top,
        endPoint: .bottom
    )
    static let fieldBackground = Color.white
    static let fieldDivider = hairline
    static let otpBoxBackground = Color.white
    static let otpBoxBorder = fieldBorder
    static let otpBoxBorderActive = brandGreen
    static let otpPlaceholderDot = brandGreenBorder
    static let accentRed = due
    static let accentGreen = brandGreen
    static let accentOrange = pending
    static let accentYellow = pending
    static let badgeSuccess = settled
    static let badgePrivate = brandGreenDark

    // MARK: - Home Canvas & Sections
    static let homeCanvas = surfaceWash
    static let homeHeaderTop = brandGreen
    static let homeHeaderBottom = brandGreenDark
    static let homeHeaderSurface = brandGreen
    static let accentSoft = brandGreenLight
    static let discountBadge = brandGreen
    static let newBadgeBackground = transitWash
    static let newBadgeText = transit
    static let imageTile = surfaceWash
    static let blackCard = Color(hex: "#161D19")
    static let blackCardMuted = Color(hex: "#94A099")
    static let categoryPanel = brandGreenLight
    static let categoryRail = surfaceWash
    static let heroTile = surfaceWash
    static let cardSoft = surfaceWash
    static let saveBadgeFill = settledWash
}

extension View {
    func spiceNavigationBar(title: String? = nil) -> some View {
        self
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(title ?? "")
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(AppTheme.brandGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(.white)
    }
}
