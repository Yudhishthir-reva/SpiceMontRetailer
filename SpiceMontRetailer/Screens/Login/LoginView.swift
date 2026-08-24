//
//  LoginView.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI

enum RetailerAccountStatus {
    case pendingReview
    case rejected
    case blocked
    case notRegistered
    case none
}

struct LoginScreen: View {
    @StateObject var viewModel: LoginViewModel = .init()
    @FocusState private var isMobileFocused: Bool
    @State private var showRegistration: Bool = false
    @State private var activeStatusDialog: RetailerAccountStatus = .none

    var body: some View {
        NavigationStack {
            ZStack {
                Color.spiceBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    // Logo and Title
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [Color.spicePrimary, Color.spicePrimaryDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 54, height: 54)
                            .overlay(
                                Text("S")
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundColor(.white)
                            )
                            .padding(.top, 14)

                        Text("Retailer Login")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Text("Enter the mobile number registered with your shop. Approved retailers receive an OTP.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                            .lineSpacing(3)
                    }

                    // Mobile Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mobile Number")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.spiceInk)

                        HStack(spacing: 8) {
                            Text("+91")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.spiceInk)
                                .frame(width: 60, height: 50)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))

                            TextField("98765 43210", text: $viewModel.mobile)
                                .keyboardType(.numberPad)
                                .textContentType(.telephoneNumber)
                                .focused($isMobileFocused)
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                .padding(.horizontal, 14)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))
                                .onChange(of: viewModel.mobile) { _, newValue in
                                    let digits = String(newValue.filter(\.isNumber).prefix(10))
                                    if digits != newValue {
                                        viewModel.mobile = digits
                                    }
                                }
                        }
                    }
                    .padding(.top, 6)

                    // Continue Button
                    SpicePrimaryButton(title: "Continue", isEnabled: !viewModel.isShowProcessing) {
                        isMobileFocused = false
                        viewModel.sendOTP()
                    }

                    // Register Now Link
                    HStack {
                        Spacer()
                        Text("New retailer?")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(Color.spiceMuted)
                        Button(action: { showRegistration = true }) {
                            Text("Register Now")
                                .font(.system(size: 12.5, weight: .heavy))
                                .foregroundColor(Color.spicePrimary)
                        }
                        Spacer()
                    }

                    Spacer()

                    // Footer Rule Text
                    VStack(spacing: 4) {
                        Text("NO PASSWORD · NO REMEMBER ME · NO SOCIAL LOGIN")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.spiceMuted.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.bottom, 12)
                }
                .padding(.horizontal, 22)

                // Status Dialogs (Screen 03)
                if activeStatusDialog != .none {
                    accountStatusOverlay
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $viewModel.goToOTP) {
                OTPVerifyScreen(
                    mobile: viewModel.mobile.trim,
                    prefilledOTP: viewModel.echoedOTP
                )
            }
            .fullScreenCover(isPresented: $showRegistration) {
                RetailerRegistrationFlowView()
            }
        }
        .toast(isPresenting: $viewModel.isShowToastView, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: viewModel.toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Account Status Blocking Modal
    @ViewBuilder
    private var accountStatusOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 12) {
                switch activeStatusDialog {
                case .pendingReview:
                    SpiceCard(backgroundColor: Color.spiceAmberLight.opacity(0.2), borderColor: Color.spiceAmber.opacity(0.4)) {
                        VStack(alignment: .leading, spacing: 8) {
                            SpiceStatusBadge(status: "PENDING_REVIEW")
                            Text("Your Account is Under Review")
                                .font(.system(size: 14.5, weight: .heavy))
                                .foregroundColor(Color.spiceInk)
                            Text("Your retailer registration has been submitted successfully and is currently being reviewed by our team. You will be able to login and place orders once approved.")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                                .lineSpacing(3)
                            SpiceGhostButton(title: "OK", height: 36) {
                                activeStatusDialog = .none
                            }
                        }
                    }

                case .rejected:
                    SpiceCard(backgroundColor: Color.spiceDueLight.opacity(0.2), borderColor: Color.spiceDue.opacity(0.4)) {
                        VStack(alignment: .leading, spacing: 8) {
                            SpiceStatusBadge(status: "REJECTED")
                            Text("Registration Not Approved")
                                .font(.system(size: 14.5, weight: .heavy))
                            Text("Your retailer registration could not be approved at this time. Please contact our support team for more information.")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                            HStack(spacing: 8) {
                                SpiceOutlinedButton(title: "Contact Support", height: 36) {
                                    activeStatusDialog = .none
                                }
                                SpiceGhostButton(title: "OK", height: 36) {
                                    activeStatusDialog = .none
                                }
                            }
                        }
                    }

                case .blocked:
                    SpiceCard(backgroundColor: Color.spiceDueLight.opacity(0.2), borderColor: Color.spiceDue.opacity(0.4)) {
                        VStack(alignment: .leading, spacing: 8) {
                            SpiceStatusBadge(status: "BLOCKED")
                            Text("Account Temporarily Blocked")
                                .font(.system(size: 14.5, weight: .heavy))
                            Text("Your retailer account is currently inactive. Please contact customer support.")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                            SpicePrimaryButton(title: "Call Support", height: 40) {
                                activeStatusDialog = .none
                                if let url = URL(string: "tel://18002004455") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }

                case .notRegistered:
                    SpiceCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SpiceStatusBadge(status: "NOT_REGISTERED")
                            Text("Retailer Account Not Found")
                                .font(.system(size: 14.5, weight: .heavy))
                            Text("This mobile number is not registered. Register your shop to get started.")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                            SpicePrimaryButton(title: "Register Now", height: 40) {
                                activeStatusDialog = .none
                                showRegistration = true
                            }
                        }
                    }

                case .none:
                    EmptyView()
                }
            }
            .padding(24)
        }
    }
}

