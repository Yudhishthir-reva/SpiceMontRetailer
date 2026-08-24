//
//  LoginViewModel.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import Foundation
import Combine

class LoginViewModel: ObservableObject {

    @Published var mobile = ""
    @Published var isShowProcessing = false
    @Published var goToOTP = false
    @Published var echoedOTP = ""
    @Published var isShowToastView = false
    @Published var toastMessage = ""

    private let service = LoginServiceManager()
    private var cancellables = Set<AnyCancellable>()

    func sendOTP() {
        let trimmed = mobile.trim
        guard trimmed.isValidIndianMobileNumber() else {
            toastMessage = "Please enter a valid 10-digit mobile number"
            isShowToastView = true
            return
        }

        isShowProcessing = true
        let params: [String: Any] = ["mobile": trimmed]

        service.sendOTP(params: params, headers: [:])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isShowProcessing = false
                if case .failure(let error) = completion {
                    self?.toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    self?.isShowToastView = true
                }
            } receiveValue: { [weak self] response in
                if response.status == true {
                    self?.echoedOTP = OTPSendModel.usableOTP(from: response.otp)
                    self?.goToOTP = true
                } else {
                    self?.toastMessage = response.message ?? "Something went wrong"
                    self?.isShowToastView = true
                }
            }
            .store(in: &cancellables)
    }
}
