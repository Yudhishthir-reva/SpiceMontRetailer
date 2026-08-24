//
//  LoginViewModel.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import Foundation
import Combine

struct AccountBlock: Equatable {
    let status: RetailerAccountStatus
    let message: String?
}

class LoginViewModel: ObservableObject {

    @Published var mobile = ""
    @Published var isShowProcessing = false
    @Published var goToOTP = false
    @Published var echoedOTP = ""
    @Published var isShowToastView = false
    @Published var toastMessage = ""
    @Published var accountBlock: AccountBlock? = nil
    @Published var cooldownSeconds: Int = 0
    @Published var mobileError: String? = nil

    private let service = LoginServiceManager()
    private var cancellables = Set<AnyCancellable>()
    private var cooldownTimer: AnyCancellable?

    var isMobileValid: Bool {
        let trimmed = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 10, let first = trimmed.first, ("6"..."9").contains(first) else {
            return false
        }
        return true
    }

    var canSubmit: Bool {
        isMobileValid && !isShowProcessing && cooldownSeconds == 0
    }

    func sendOTP() {
        let trimmed = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isMobileValid else {
            mobileError = "Enter a valid 10-digit mobile number starting with 6-9"
            toastMessage = "Enter a valid 10-digit mobile number"
            isShowToastView = true
            return
        }
        mobileError = nil
        accountBlock = nil

        isShowProcessing = true
        let params: [String: Any] = ["mobile": trimmed]

        service.sendOTP(params: params, headers: [:])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isShowProcessing = false
                if case .failure(let error) = completion {
                    let errStr = (error as? RequestError)?.errorString ?? error.localizedDescription
                    if errStr.localizedCaseInsensitiveContains("429") || errStr.localizedCaseInsensitiveContains("too many") {
                        self?.startCooldown(seconds: 30)
                        self?.toastMessage = "Too many attempts. Please wait 30 seconds."
                    } else if errStr.localizedCaseInsensitiveContains("404") || errStr.localizedCaseInsensitiveContains("not registered") || errStr.localizedCaseInsensitiveContains("not found") {
                        self?.accountBlock = AccountBlock(status: .notRegistered, message: errStr)
                    } else if errStr.localizedCaseInsensitiveContains("403") || errStr.localizedCaseInsensitiveContains("block") || errStr.localizedCaseInsensitiveContains("inactive") {
                        self?.accountBlock = AccountBlock(status: .blocked, message: errStr)
                    } else if errStr.localizedCaseInsensitiveContains("pending") {
                        self?.accountBlock = AccountBlock(status: .pendingReview, message: errStr)
                    } else {
                        self?.toastMessage = errStr
                        self?.isShowToastView = true
                    }
                }
            } receiveValue: { [weak self] response in
                if response.status == true {
                    self?.echoedOTP = OTPSendModel.usableOTP(from: response.otp)
                    self?.goToOTP = true
                } else {
                    let msg = response.message ?? "Something went wrong"
                    if msg.localizedCaseInsensitiveContains("pending") {
                        self?.accountBlock = AccountBlock(status: .pendingReview, message: msg)
                    } else if msg.localizedCaseInsensitiveContains("reject") {
                        self?.accountBlock = AccountBlock(status: .rejected, message: msg)
                    } else if msg.localizedCaseInsensitiveContains("block") || msg.localizedCaseInsensitiveContains("inactive") {
                        self?.accountBlock = AccountBlock(status: .blocked, message: msg)
                    } else if msg.localizedCaseInsensitiveContains("not registered") || msg.localizedCaseInsensitiveContains("not found") {
                        self?.accountBlock = AccountBlock(status: .notRegistered, message: msg)
                    } else {
                        self?.toastMessage = msg
                        self?.isShowToastView = true
                    }
                }
            }
            .store(in: &cancellables)
    }

    func startCooldown(seconds: Int) {
        cooldownSeconds = seconds
        cooldownTimer?.cancel()
        cooldownTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.cooldownSeconds > 0 {
                    self.cooldownSeconds -= 1
                } else {
                    self.cooldownTimer?.cancel()
                }
            }
    }
}
