//
//  SplashScreen.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI

struct SplashScreen: View {

    // MARK: - Animation state

    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showTagline = false
    @State private var showDash = false
    @State private var showLoader = false
    @State private var logoScale: CGFloat = 0.4
    @State private var navigateAway = false

    /// Continuous gentle rotation for the logo spice ring.
    @State private var ringRotation: Double = 0

    /// Pulsing glow behind the logo.
    @State private var glowPulse = false

    private let defaults = UserDefaultManager.shared

    var body: some View {
        ZStack {
            // Background
            AnimatedBrandBackground()
            SplashSpiceField()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Logo cluster
                ZStack {
                    // Glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppTheme.brandGreen.opacity(glowPulse ? 0.28 : 0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(glowPulse ? 1.15 : 0.95)

                    // Decorative spice ring — four tiny spices orbiting
                    SpiceOrbitRing()
                        .frame(width: 170, height: 170)
                        .rotationEffect(.degrees(ringRotation))

                    // Central logo mark
                    SpiceMonkLogoMark()
                        .frame(width: 100, height: 100)
                        .scaleEffect(logoScale)
                        .opacity(showLogo ? 1 : 0)
                }

                // MARK: Title
                Text("SpiceMonk")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.brandGreenLight, AppTheme.brandGreen, AppTheme.brandGreenDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 18)
                    .padding(.top, 20)

                // MARK: Accent dash
                AccentDash()
                    .opacity(showDash ? 1 : 0)
                    .scaleEffect(showDash ? 1 : 0.3)
                    .padding(.top, 12)

                // MARK: Tagline
                Text("India's finest flavours,\ndelivered to your doorstep.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline ? 0 : 12)
                    .padding(.top, 14)
                    .padding(.horizontal, 40)

                Spacer()

                // MARK: Loading dots
                if showLoader {
                    LoadingDots()
                        .transition(.opacity.combined(with: .scale(scale: 0.6)))
                        .padding(.bottom, 8)
                }

                Text("Powered by Reva")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textMuted)
                    .opacity(showLoader ? 1 : 0)
                    .padding(.bottom, 28)
            }
        }
        .onAppear(perform: startAnimationSequence)
        .fullScreenCover(isPresented: $navigateAway) {
            destinationView
        }
    }

    // MARK: - Destination

    @ViewBuilder
    private var destinationView: some View {
        if defaults.isUserLoggedIn {
            MainTabView()
        } else {
            LoginScreen()
        }
    }

    // MARK: - Animation timeline

    private func startAnimationSequence() {
        // Continuous ring rotation
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }

        // Continuous glow pulse
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            glowPulse = true
        }

        // T+0.2s — Logo appears with spring
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6, blendDuration: 0)) {
                showLogo = true
                logoScale = 1.0
            }
        }

        // T+0.7s — Title slides up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.5)) {
                showTitle = true
            }
        }

        // T+1.0s — Accent dash pops
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                showDash = true
            }
        }

        // T+1.3s — Tagline fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                showTagline = true
            }
        }

        // T+1.6s — Loading dots appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.4)) {
                showLoader = true
            }
        }

        // T+2.8s — Navigate away
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            navigateAway = true
        }
    }
}

// MARK: - SpiceMonk Logo Mark (SwiftUI drawn)

/// A leaf-in-mortar logo mark drawn purely in SwiftUI — no image assets needed.
struct SpiceMonkLogoMark: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // Background circle
            let circleRect = CGRect(x: w * 0.05, y: h * 0.05, width: w * 0.9, height: h * 0.9)
            context.fill(
                Path(ellipseIn: circleRect),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "1E8A52"), Color(hex: "167444"), Color(hex: "0E4A28")]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: w, y: h)
                )
            )

            // Inner glow ring
            let innerRing = CGRect(x: w * 0.12, y: h * 0.12, width: w * 0.76, height: h * 0.76)
            context.stroke(
                Path(ellipseIn: innerRing),
                with: .color(.white.opacity(0.18)),
                lineWidth: w * 0.02
            )

            // Mortar (bowl shape)
            var mortar = Path()
            mortar.move(to: CGPoint(x: w * 0.25, y: h * 0.48))
            mortar.addCurve(
                to: CGPoint(x: w * 0.75, y: h * 0.48),
                control1: CGPoint(x: w * 0.25, y: h * 0.48),
                control2: CGPoint(x: w * 0.75, y: h * 0.48)
            )
            mortar.addCurve(
                to: CGPoint(x: w * 0.5, y: h * 0.78),
                control1: CGPoint(x: w * 0.78, y: h * 0.66),
                control2: CGPoint(x: w * 0.66, y: h * 0.78)
            )
            mortar.addCurve(
                to: CGPoint(x: w * 0.25, y: h * 0.48),
                control1: CGPoint(x: w * 0.34, y: h * 0.78),
                control2: CGPoint(x: w * 0.22, y: h * 0.66)
            )
            mortar.closeSubpath()
            context.fill(mortar, with: .color(.white.opacity(0.92)))

            // Mortar rim
            var rim = Path()
            rim.move(to: CGPoint(x: w * 0.22, y: h * 0.50))
            rim.addLine(to: CGPoint(x: w * 0.78, y: h * 0.50))
            context.stroke(
                rim,
                with: .color(.white),
                style: StrokeStyle(lineWidth: w * 0.035, lineCap: .round)
            )

            // Pestle (diagonal)
            var pestle = Path()
            pestle.move(to: CGPoint(x: w * 0.58, y: h * 0.44))
            pestle.addLine(to: CGPoint(x: w * 0.74, y: h * 0.24))
            context.stroke(
                pestle,
                with: .color(.white.opacity(0.92)),
                style: StrokeStyle(lineWidth: w * 0.06, lineCap: .round)
            )

            // Pestle knob
            let knobSize = w * 0.08
            context.fill(
                Path(ellipseIn: CGRect(
                    x: w * 0.74 - knobSize / 2,
                    y: h * 0.22 - knobSize / 2,
                    width: knobSize,
                    height: knobSize
                )),
                with: .color(.white.opacity(0.92))
            )

            // Leaf accent — a small leaf sticking out of the mortar
            var leaf = Path()
            leaf.move(to: CGPoint(x: w * 0.42, y: h * 0.46))
            leaf.addCurve(
                to: CGPoint(x: w * 0.30, y: h * 0.28),
                control1: CGPoint(x: w * 0.34, y: h * 0.42),
                control2: CGPoint(x: w * 0.26, y: h * 0.34)
            )
            leaf.addCurve(
                to: CGPoint(x: w * 0.46, y: h * 0.42),
                control1: CGPoint(x: w * 0.34, y: h * 0.24),
                control2: CGPoint(x: w * 0.44, y: h * 0.32)
            )
            leaf.closeSubpath()
            context.fill(leaf, with: .color(Color(hex: "A8D86A")))

            // Leaf vein
            var vein = Path()
            vein.move(to: CGPoint(x: w * 0.43, y: h * 0.44))
            vein.addLine(to: CGPoint(x: w * 0.33, y: h * 0.30))
            context.stroke(
                vein,
                with: .color(Color(hex: "6B9D3A").opacity(0.7)),
                style: StrokeStyle(lineWidth: w * 0.012, lineCap: .round)
            )
        }
    }
}

// MARK: - Spice Orbit Ring

/// Four tiny spice illustrations orbiting around the centre in a ring formation.
struct SpiceOrbitRing: View {

    private let spices: [(SpiceKind, Angle)] = [
        (.starAnise, .degrees(0)),
        (.redChilli, .degrees(90)),
        (.cardamom, .degrees(180)),
        (.bayLeaf, .degrees(270)),
    ]

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 14

            ForEach(Array(spices.enumerated()), id: \.offset) { _, item in
                let angle = item.1.radians
                SpiceIllustration(kind: item.0)
                    .frame(width: 28, height: 28)
                    .opacity(0.55)
                    .position(
                        x: center.x + radius * cos(angle),
                        y: center.y + radius * sin(angle)
                    )
            }
        }
    }
}

// MARK: - Loading Dots

/// Three bouncing dots that stagger, matching the SpiceMonk brand green.
struct LoadingDots: View {

    @State private var bounce = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(AppTheme.brandGreen)
                    .frame(width: 8, height: 8)
                    .offset(y: bounce ? -6 : 0)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                        value: bounce
                    )
            }
        }
        .onAppear { bounce = true }
    }
}

// MARK: - Preview

#Preview {
    SplashScreen()
}
