//
//  OTPVerifyScreen.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI
import Combine

struct OTPVerifyScreen: View {

    let mobile: String
    var prefilledOTP: String = ""

    @StateObject private var viewModel = OTPVerifyViewModel()
    @FocusState private var focusedIndex: Int?
    @Environment(\.dismiss) private var dismiss

    var maskedMobile: String {
        guard mobile.count >= 4 else { return mobile }
        let prefix = mobile.prefix(2)
        let suffix = mobile.suffix(2)
        return "+91 \(prefix)•••\(suffix)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            SpiceTopBar(title: "OTP Verification", showBack: true, onBack: {
                dismiss()
            })

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Enter the 6-digit OTP sent to")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.spiceMuted)

                        Text(maskedMobile)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.spiceInk)
                    }
                    .padding(.top, 14)

                    // 6-digit OTP Boxes
                    otpBoxes

                    // Resend and Timer
                    HStack {
                        if viewModel.resendSeconds > 0 {
                            Text("Resend OTP in ")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.spiceMuted) +
                            Text(String(format: "00:%02d", viewModel.resendSeconds))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.spiceInk)
                        } else {
                            Text("Didn't receive OTP?")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                        }

                        Spacer()

                        Button(action: {
                            if viewModel.resendSeconds == 0 {
                                viewModel.resendOTP(mobile: mobile)
                            }
                        }) {
                            Text("Resend OTP")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(viewModel.resendSeconds == 0 ? Color.spicePrimary : Color.spiceMuted.opacity(0.4))
                        }
                        .disabled(viewModel.resendSeconds > 0)
                    }

                    // Verify & Login Button
                    SpicePrimaryButton(title: "Verify & Login", isEnabled: !viewModel.isVerifying) {
                        focusedIndex = nil
                        viewModel.verifyOTP(mobile: mobile)
                    }
                    .padding(.top, 6)

                    // Change Mobile Button
                    Button(action: { dismiss() }) {
                        Text("Change Mobile Number")
                            .font(.system(size: 12.5, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 4)

                    // Error Alert Preview / State
                    if !viewModel.toastMessage.isEmpty && viewModel.isShowToast {
                        SpiceCard(backgroundColor: Color.spiceDueLight.opacity(0.3), borderColor: Color.spiceDue.opacity(0.4), padding: 12) {
                            HStack(spacing: 8) {
                                Circle().fill(Color.spiceDue).frame(width: 6, height: 6)
                                Text(viewModel.toastMessage)
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(Color.spiceDue)
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
            }
            .background(Color.spiceBackground)
        }
        .navigationBarHidden(true)
        .onAppear {
            if !prefilledOTP.isEmpty {
                for (i, ch) in prefilledOTP.prefix(6).enumerated() {
                    viewModel.digits[i] = String(ch)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedIndex = prefilledOTP.isEmpty ? 0 : nil
            }
            viewModel.startResendTimer()
        }
        .toast(isPresenting: $viewModel.isShowToast, duration: 1.8, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: viewModel.toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - OTP boxes
    private var otpBoxes: some View {
        HStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                ZStack {
                    if viewModel.digits[index].isEmpty {
                        Text("—")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.spiceMuted.opacity(0.4))
                    } else {
                        Text(viewModel.digits[index])
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.spiceInk)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(focusedIndex == index ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: focusedIndex == index ? 1.8 : 1)
                )
                .background {
                    TextField("", text: $viewModel.digits[index])
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($focusedIndex, equals: index)
                        .opacity(0.01)
                        .onChange(of: viewModel.digits[index]) { _, newValue in
                            let filtered = String(newValue.filter(\.isNumber).prefix(1))
                            if filtered != newValue {
                                viewModel.digits[index] = filtered
                            }
                            if !filtered.isEmpty && index < 5 {
                                focusedIndex = index + 1
                            }
                        }
                }
                .onTapGesture {
                    focusedIndex = index
                }
            }
        }
    }
}


// MARK: - ViewModel

class OTPVerifyViewModel: ObservableObject {

    @Published var digits: [String] = Array(repeating: "", count: 6)
    @Published var isVerifying = false
    @Published var isShowToast = false
    @Published var toastMessage = ""
    @Published var resendSeconds = 30

    private let service = LoginServiceManager()
    private let defaults = UserDefaultManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var resendTimer: AnyCancellable?

    var otpString: String { digits.joined() }

    func startResendTimer() {
        resendSeconds = 30
        resendTimer?.cancel()
        resendTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.resendSeconds > 0 else { return }
                self.resendSeconds -= 1
                if self.resendSeconds == 0 { self.resendTimer?.cancel() }
            }
    }

    func resendOTP(mobile: String) {
        let params: [String: Any] = ["mobile": mobile]
        service.sendOTP(params: params, headers: [:])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    self?.isShowToast = true
                }
            } receiveValue: { [weak self] response in
                if response.status == true {
                    self?.toastMessage = response.message ?? "OTP sent successfully"
                    self?.isShowToast = true
                    self?.startResendTimer()
                    // Prefill if echoed
                    let echoed = OTPSendModel.usableOTP(from: response.otp)
                    if !echoed.isEmpty {
                        for (i, ch) in echoed.prefix(6).enumerated() {
                            self?.digits[i] = String(ch)
                        }
                    }
                } else {
                    self?.toastMessage = response.message ?? "Failed to send OTP"
                    self?.isShowToast = true
                }
            }
            .store(in: &cancellables)
    }

    func verifyOTP(mobile: String) {
        let otp = otpString
        guard otp.count == 6 else {
            toastMessage = "Please enter complete 6-digit OTP"
            isShowToast = true
            return
        }

        isVerifying = true
        let params: [String: Any] = ["mobile": mobile, "otp": otp]

        service.verifyOTP(params: params, headers: [:])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isVerifying = false
                if case .failure(let error) = completion {
                    self?.toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    self?.isShowToast = true
                }
            } receiveValue: { [weak self] response in
                if response.status == true {
                    self?.saveUserData(response)
                    self?.navigateToHome()
                } else {
                    self?.toastMessage = response.message ?? "Invalid OTP"
                    self?.isShowToast = true
                }
            }
            .store(in: &cancellables)
    }

    private func saveUserData(_ response: OTPVerifyModel) {
        defaults.setUserDefaultsString(value: response.accessToken ?? "", key: .authToken)
        defaults.setUserDefaultsString(value: response.refreshToken ?? "", key: .refreshToken)
        defaults.setUserDefaultsString(value: response.sellerId ?? "", key: .sellerId)
        defaults.setUserDefaultsString(value: response.mobile ?? "", key: .userMobile)
        defaults.setUserDefaultsString(value: response.name ?? "", key: .userName)
        defaults.setTokenExpiry(secondsFromNow: response.expiresIn)
    }

    private func navigateToHome() {
        AppRootManager.shared.setRootView(view: MainTabView())
    }
}

#Preview {
    NavigationStack {
        OTPVerifyScreen(mobile: "9876543210")
    }
}
