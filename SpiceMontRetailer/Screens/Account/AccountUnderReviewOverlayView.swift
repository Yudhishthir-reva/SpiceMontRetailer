//
//  AccountUnderReviewOverlayView.swift
//  SpiceMontRetailer
//
//  Created on 29/08/26.
//

import SwiftUI

struct AccountUnderReviewOverlayView: View {
    @ObservedObject private var configManager = AppConfigManager.shared
    @State private var showLogoutConfirmation: Bool = false
    @State private var isChecking: Bool = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""

    private var supportNumber: String {
        configManager.customerSupportNumber.isEmpty ? "18002004455" : configManager.customerSupportNumber
    }

    var body: some View {
        ZStack {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top Header
                HStack(spacing: 10) {
                    Image("spice_monk_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 1) {
                        Text("SpiceMonk")
                            .font(.appFont(size: 17, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Text("BUSINESS")
                            .font(.appFont(size: 9.5, weight: .heavy))
                            .foregroundColor(Color.spicePrimary)
                            .tracking(0.5)
                    }

                    Spacer()

                    // Quick Refresh Button
                    Button(action: recheckStatus) {
                        Image(systemName: isChecking ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.spiceInk)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.spiceCardBorder, lineWidth: 1))
                    }
                    .disabled(isChecking)
                    .buttonStyle(.plain)

                    // Quick Logout Button
                    Button(action: {
                        showLogoutConfirmation = true
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.spiceDue)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.spiceCardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(Color.white)
                .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

                // MARK: - Center Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        Spacer(minLength: 40)

                        // Hourglass Icon Circle
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#FDF0DC"))
                                .frame(width: 76, height: 76)

                            Image(systemName: "hourglass")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(Color(hex: "#A85B08"))
                        }

                        // Status Badge
                        Text("PENDING REVIEW")
                            .font(.appFont(size: 11, weight: .heavy))
                            .foregroundColor(Color(hex: "#A85B08"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color(hex: "#FDF0DC"))
                            .cornerRadius(6)

                        // Title
                        Text("Your Account is Under Review")
                            .font(.appFont(size: 20, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                            .multilineTextAlignment(.center)

                        // Description
                        VStack(spacing: 12) {
                            let message = configManager.accountPendingMessage.isEmpty ? "Your registration has been submitted successfully!\n\nYour details have been sent for review.\nYou will be notified once your account is approved by our team." : configManager.accountPendingMessage
                            let parts = message.components(separatedBy: "\n\n")

                            if parts.count > 1 {
                                Text(parts[0])
                                    .font(.appFont(size: 13.5, weight: .bold))
                                    .foregroundColor(Color.spiceInk)
                                    .multilineTextAlignment(.center)

                                Text(parts.dropFirst().joined(separator: "\n\n"))
                                    .font(.appFont(size: 13, weight: .medium))
                                    .foregroundColor(Color.spiceMuted)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                            } else {
                                Text(message)
                                    .font(.appFont(size: 13, weight: .medium))
                                    .foregroundColor(Color.spiceMuted)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                            }
                        }
                        .padding(.horizontal, 28)

                        // MARK: - Action Buttons
                        VStack(spacing: 12) {
                            // 1. Contact Support Button
                            Button(action: contactSupport) {
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Contact Support")
                                        .font(.appFont(size: 14, weight: .heavy))
                                }
                                .foregroundColor(Color.spicePrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.spicePrimary, lineWidth: 1.5)
                                )
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)

                            // 2. Check Status / Refresh Button
                            Button(action: recheckStatus) {
                                HStack(spacing: 8) {
                                    if isChecking {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                    Text(isChecking ? "Checking Status..." : "Check Approval Status")
                                        .font(.appFont(size: 14, weight: .heavy))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.spicePrimary)
                                .cornerRadius(12)
                            }
                            .disabled(isChecking)
                            .buttonStyle(.plain)

                            // 3. Log Out Button
                            Button(action: {
                                showLogoutConfirmation = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Log Out")
                                        .font(.appFont(size: 14, weight: .heavy))
                                }
                                .foregroundColor(Color.spiceDue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.spiceDue.opacity(0.4), lineWidth: 1.2)
                                )
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 14)

                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .toast(isPresenting: $showToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
        .confirmationDialog(
            "Are you sure you want to log out?",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                configManager.performLogout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to sign in again with your mobile number.")
        }
    }

    private func contactSupport() {
        let phone = supportNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func recheckStatus() {
        isChecking = true
        configManager.recheckAccountApproval { isStillPending in
            isChecking = false
            if isStillPending {
                let firstLine = configManager.accountPendingMessage.components(separatedBy: "\n").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                toastMessage = firstLine.isEmpty ? "Account is under review. Please wait for admin approval." : firstLine
                showToast = true
            } else {
                toastMessage = "Account is approved!"
                showToast = true
            }
        }
    }
}

#Preview {
    AccountUnderReviewOverlayView()
}
