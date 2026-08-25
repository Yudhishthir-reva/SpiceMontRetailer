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

typealias LoginView = LoginScreen

struct LoginScreen: View {
    @StateObject var viewModel: LoginViewModel = .init()
    @FocusState private var isMobileFocused: Bool
    @State private var showRegistration: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.spiceBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Logo and Title
                        VStack(alignment: .leading, spacing: 8) {
                            Image("spice_monk_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
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
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(viewModel.mobileError != nil ? Color.spiceDue : Color.spiceCardBorder, lineWidth: 1)
                                    )
                                    .onChange(of: viewModel.mobile) { _, newValue in
                                        let digits = String(newValue.filter(\.isNumber).prefix(10))
                                        if digits != newValue {
                                            viewModel.mobile = digits
                                        }
                                        if viewModel.accountBlock != nil {
                                            viewModel.accountBlock = nil
                                        }
                                        if viewModel.mobileError != nil {
                                            viewModel.mobileError = nil
                                        }
                                    }
                            }

                            if let err = viewModel.mobileError {
                                Text(err)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.spiceDue)
                            }
                        }
                        .padding(.top, 6)

                        // Inline Account Block Card (Screen 03)
                        if let block = viewModel.accountBlock {
                            accountBlockInlineCard(block: block)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Continue Button with Cooldown state
                        let buttonTitle = viewModel.cooldownSeconds > 0
                            ? "Wait \(viewModel.cooldownSeconds)s"
                            : (viewModel.isShowProcessing ? "Sending..." : "Continue")

                        SpicePrimaryButton(
                            title: buttonTitle,
                            isEnabled: viewModel.canSubmit
                        ) {
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

                        Spacer(minLength: 40)

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
                }
            }
            .navigationBarHidden(true)
            .animation(.easeInOut(duration: 0.25), value: viewModel.accountBlock != nil)
            .navigationDestination(isPresented: $viewModel.goToOTP) {
                OTPVerifyScreen(
                    mobile: viewModel.mobile.trimmingCharacters(in: .whitespacesAndNewlines),
                    prefilledOTP: viewModel.echoedOTP
                )
            }
            .fullScreenCover(isPresented: $showRegistration) {
                RetailerRegistrationFlowView(initialMobile: viewModel.mobile)
            }
        }
        .toast(isPresenting: $viewModel.isShowToastView, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: viewModel.toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Account Block Inline Card (Screen 03)
    @ViewBuilder
    private func accountBlockInlineCard(block: AccountBlock) -> some View {
        switch block.status {
        case .pendingReview:
            SpiceCard(backgroundColor: Color.spiceAmberLight.opacity(0.25), borderColor: Color.spiceAmber.opacity(0.4)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        SpiceStatusBadge(status: "PENDING_REVIEW")
                        Spacer()
                        Button(action: { viewModel.accountBlock = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.spiceMuted)
                        }
                    }
                    Text("Your Account is Under Review")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                    Text(block.message?.isEmpty == false ? block.message! : "Your registration has been submitted and is being reviewed by our team. You will be able to place orders once approved.")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                        .lineSpacing(2)
                    HStack(spacing: 8) {
                        SpiceGhostButton(title: "Contact Support", height: 34) {
                            if let url = URL(string: "tel://18002004455") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
            }

        case .rejected:
            SpiceCard(backgroundColor: Color.spiceDueLight.opacity(0.25), borderColor: Color.spiceDue.opacity(0.4)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        SpiceStatusBadge(status: "REJECTED")
                        Spacer()
                        Button(action: { viewModel.accountBlock = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.spiceMuted)
                        }
                    }
                    Text("Registration Not Approved")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                    Text(block.message?.isEmpty == false ? block.message! : "Your retailer registration could not be approved at this time. Please contact our support team for more details.")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                    SpicePrimaryButton(title: "Call Support", height: 36) {
                        if let url = URL(string: "tel://18002004455") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }

        case .blocked:
            SpiceCard(backgroundColor: Color.spiceDueLight.opacity(0.25), borderColor: Color.spiceDue.opacity(0.4)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        SpiceStatusBadge(status: "BLOCKED")
                        Spacer()
                        Button(action: { viewModel.accountBlock = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.spiceMuted)
                        }
                    }
                    Text("Account Temporarily Blocked")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                    Text(block.message?.isEmpty == false ? block.message! : "Your retailer account is currently inactive. Please contact customer support.")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                    SpicePrimaryButton(title: "Call Support", height: 36) {
                        if let url = URL(string: "tel://18002004455") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }

        case .notRegistered:
            SpiceCard(backgroundColor: Color.white, borderColor: Color.spicePrimary.opacity(0.4)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        SpiceStatusBadge(status: "NOT_REGISTERED")
                        Spacer()
                        Button(action: { viewModel.accountBlock = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.spiceMuted)
                        }
                    }
                    Text("Retailer Account Not Found")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                    Text(block.message?.isEmpty == false ? block.message! : "We could not find a registered retailer account for this mobile number. Register your shop to get started.")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                    SpicePrimaryButton(title: "Register Now", height: 36) {
                        viewModel.accountBlock = nil
                        showRegistration = true
                    }
                }
            }

        case .none:
            EmptyView()
        }
    }
}

