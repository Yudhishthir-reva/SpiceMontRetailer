//
//  AppStatusDialogs.swift
//  SpiceMontRetailer
//

import SwiftUI

// MARK: - Maintenance Dialog View

struct MaintenanceDialogView: View {

    @ObservedObject private var manager = AppConfigManager.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.spicePrimaryLight)
                        .frame(width: 84, height: 84)

                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.appFont(size: 38, weight: .semibold))
                        .foregroundColor(Color.spicePrimary)
                }
                .padding(.top, 8)

                VStack(spacing: 8) {
                    Text("MAINTENANCE")
                        .font(.appFont(size: 11, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.spicePrimaryLight)
                        .clipShape(Capsule())

                    Text("We'll Be Back Soon!")
                        .font(.appFont(size: 22, weight: .bold))
                        .foregroundColor(Color.spiceInk)

                    Text("SpiceMonk Retailer is undergoing scheduled maintenance to improve your experience. Please check back shortly.")
                        .font(.appFont(size: 14, weight: .regular))
                        .foregroundColor(Color.spiceMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Retry Button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    manager.checkStatus()
                } label: {
                    HStack(spacing: 8) {
                        if manager.isCheckingStatus {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.appFont(size: 15, weight: .bold))
                        }
                        Text(manager.isCheckingStatus ? "Checking..." : "Retry")
                            .font(.appFont(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.spicePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(manager.isCheckingStatus)
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 20, y: 10)
            .padding(.horizontal, 28)
        }
    }
}

// MARK: - Update Dialog View (Force & Soft)

struct AppUpdateDialogView: View {

    let isForce: Bool
    let message: String
    let onUpdate: () -> Void
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.spicePrimaryLight)
                        .frame(width: 84, height: 84)

                    Image(systemName: isForce ? "arrow.triangle.2.circlepath.circle.fill" : "sparkles")
                        .font(.appFont(size: 40, weight: .semibold))
                        .foregroundColor(Color.spicePrimary)
                }
                .padding(.top, 8)

                VStack(spacing: 8) {
                    Text(isForce ? "UPDATE REQUIRED" : "NEW VERSION AVAILABLE")
                        .font(.appFont(size: 11, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.spicePrimaryLight)
                        .clipShape(Capsule())

                    Text(isForce ? "Time to Update!" : "Exciting New Updates!")
                        .font(.appFont(size: 22, weight: .bold))
                        .foregroundColor(Color.spiceInk)

                    Text(message.isEmpty ? "A brand new version of SpiceMonk Retailer is ready with exciting features and improvements. Update now to enjoy the best experience." : message)
                        .font(.appFont(size: 14, weight: .regular))
                        .foregroundColor(Color.spiceMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 10) {
                    // Update CTA
                    Button(action: onUpdate) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.appFont(size: 17, weight: .bold))
                            Text("Update Now")
                                .font(.appFont(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.spicePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    // Optional Later CTA
                    if !isForce, let onDismiss = onDismiss {
                        Button(action: onDismiss) {
                            Text("Maybe Later")
                                .font(.appFont(size: 14, weight: .semibold))
                                .foregroundColor(Color.spiceMuted)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 20, y: 10)
            .padding(.horizontal, 28)
        }
    }
}

// MARK: - View Modifier for Overlays

struct AppStatusOverlayModifier: ViewModifier {

    @ObservedObject private var manager = AppConfigManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content

            if manager.isMaintenance {
                MaintenanceDialogView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(999999)
            } else if manager.isForceUpdate {
                AppUpdateDialogView(
                    isForce: true,
                    message: manager.updateMessage,
                    onUpdate: {
                        if let url = manager.resolvedUpdateURL {
                            UIApplication.shared.open(url)
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(999998)
            } else if manager.isSoftUpdate {
                AppUpdateDialogView(
                    isForce: false,
                    message: manager.updateMessage,
                    onUpdate: {
                        if let url = manager.resolvedUpdateURL {
                            UIApplication.shared.open(url)
                        }
                    },
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.25)) {
                            manager.dismissSoftUpdate()
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(999997)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: manager.isMaintenance)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: manager.isForceUpdate)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: manager.isSoftUpdate)
    }
}

extension View {
    func handleAppStatusOverlays() -> some View {
        modifier(AppStatusOverlayModifier())
    }
}
