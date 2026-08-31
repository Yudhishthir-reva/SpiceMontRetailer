//
//  PaymentRequestManager.swift
//  SpiceMontRetailer
//
//  Created on 29/08/26.
//

import Foundation
import Combine
import SwiftUI

public class PaymentRequestManager: ObservableObject {
    public static let shared = PaymentRequestManager()

    @Published public var requests: [PaymentRequestSubmitData] = []
    @Published public var isSubmitting: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var isShowToast: Bool = false
    @Published public var toastMessage: String = ""

    private let localKey = "SavedPaymentRequests_v1"
    private let orderService = OrderServiceManager()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadSavedRequests()
    }

    public func loadSavedRequests() {
        if let data = UserDefaults.standard.data(forKey: localKey),
           let saved = try? JSONDecoder().decode([PaymentRequestSubmitData].self, from: data) {
            self.requests = saved
        }
    }

    private func persistRequests() {
        if let encoded = try? JSONEncoder().encode(self.requests) {
            UserDefaults.standard.set(encoded, forKey: localKey)
        }
    }

    public func fetchRemoteRequests() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader

        orderService.fetchPaymentRequests(page: 1, perPage: 30, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                if response.status == true, let list = response.data?.data, !list.isEmpty {
                    // Merge remote with local
                    var combined = list
                    for localItem in self.requests {
                        if !combined.contains(where: { $0.id == localItem.id }) {
                            combined.append(localItem)
                        }
                    }
                    self.requests = combined
                    self.persistRequests()
                }
            }
            .store(in: &cancellables)
    }

    public func submitRequest(
        amount: Double,
        message: String,
        paymentMode: String = "UPI",
        referenceNumber: String = "",
        attachment: String? = nil,
        completion: @escaping (Bool, String) -> Void
    ) {
        guard amount > 0 else {
            completion(false, "Please enter a valid amount")
            return
        }

        isSubmitting = true
        let headers = UserDefaultManager.shared.authHeader

        let fullMessage = referenceNumber.isEmpty
            ? message
            : "\(message) (Ref/UTR: \(referenceNumber), Mode: \(paymentMode))".trimmingCharacters(in: .whitespaces)

        orderService.submitPaymentRequest(amount: amount, message: fullMessage.isEmpty ? "Payment submission" : fullMessage, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionResult in
                guard let self = self else { return }
                self.isSubmitting = false
                if case .failure(let error) = completionResult {
                    // Fallback to local save if offline / error
                    let fallbackItem = PaymentRequestSubmitData(
                        id: Int(Date().timeIntervalSince1970),
                        amount: amount,
                        message: fullMessage,
                        attachment: attachment,
                        status: 0,
                        statusText: "Pending",
                        statusColor: "#FFA500",
                        adminRemark: nil,
                        createdAt: self.currentFormattedDate(),
                        paymentMode: paymentMode,
                        referenceNumber: referenceNumber
                    )
                    self.requests.insert(fallbackItem, at: 0)
                    self.persistRequests()
                    let msg = (error as? RequestError)?.errorString ?? error.localizedDescription
                    completion(true, "Payment request recorded. \(msg)")
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.isSubmitting = false
                if response.status == true {
                    var item = response.data ?? PaymentRequestSubmitData(
                        id: Int(Date().timeIntervalSince1970),
                        amount: amount,
                        message: fullMessage,
                        attachment: attachment,
                        status: 0,
                        statusText: "Pending",
                        statusColor: "#FFA500",
                        adminRemark: nil,
                        createdAt: self.currentFormattedDate(),
                        paymentMode: paymentMode,
                        referenceNumber: referenceNumber
                    )
                    if item.paymentMode == nil { item.paymentMode = paymentMode }
                    if item.referenceNumber == nil { item.referenceNumber = referenceNumber }
                    if item.message == nil { item.message = fullMessage }
                    if item.attachment == nil { item.attachment = attachment }

                    self.requests.insert(item, at: 0)
                    self.persistRequests()
                    completion(true, response.message ?? "Payment request submitted successfully")
                } else {
                    completion(false, response.message ?? "Failed to submit payment request")
                }
            }
            .store(in: &cancellables)
    }

    private func currentFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, h:mm a"
        return formatter.string(from: Date())
    }
}

// Make PaymentRequestSubmitData Encodable as well for persistence
extension PaymentRequestSubmitData: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(amount, forKey: .amount)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(attachment, forKey: .attachment)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(statusText, forKey: .statusText)
        try container.encodeIfPresent(statusColor, forKey: .statusColor)
        try container.encodeIfPresent(adminRemark, forKey: .adminRemark)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(paymentMode, forKey: .paymentMode)
        try container.encodeIfPresent(referenceNumber, forKey: .referenceNumber)
    }
}
