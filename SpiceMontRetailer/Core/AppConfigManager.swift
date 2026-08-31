//
//  AppConfigManager.swift
//  SpiceMontRetailer
//

import Foundation
import Combine
import SwiftUI

public class AppConfigManager: ObservableObject {
    public static let shared = AppConfigManager()

    @Published public var config: RetailerConfigData?
    @Published public var customerSupportNumber: String = ""
    @Published public var charges: RetailerConfigCharges?
    @Published public var accountDetails: RetailerAccountDetails?
    @Published public var isLoading: Bool = false

    // App Status & Update Properties
    @Published public var isCheckingStatus: Bool = false
    @Published public var isMaintenance: Bool = false
    @Published public var isForceUpdate: Bool = false
    @Published public var isSoftUpdate: Bool = false
    @Published public var updateUrl: String = ""
    @Published public var updateMessage: String = ""

    // Account Review & Approval Properties
    @Published public var isAccountPending: Bool = false
    @Published public var accountPendingMessage: String = ""

    private let defaults = UserDefaultManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        let cachedSupport = defaults.getUserDefaultsString(key: .customerSupportPhone)
        if !cachedSupport.isEmpty {
            self.customerSupportNumber = cachedSupport
        }
        let cachedStatus = defaults.getUserDefaultsString(key: .sellerStatus).lowercased()
        if cachedStatus == "pending" || cachedStatus == "under_review" || cachedStatus == "pending_review" {
            self.isAccountPending = true
        }
    }

    public var resolvedUpdateURL: URL? {
        if !updateUrl.isEmpty, let url = URL(string: updateUrl.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return url
        }
        return URL(string: "https://spicemonk.revateam.com")
    }

    public func dismissSoftUpdate() {
        self.isSoftUpdate = false
    }

    /// Re-checks if retailer registration has been approved by admin
    public func recheckAccountApproval(completion: ((Bool) -> Void)? = nil) {
        let headers = defaults.authHeader
        guard !headers.isEmpty else {
            completion?(true)
            return
        }

        var didHandleValue = false
        HomeServiceManager().fetchRetailerHome(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionResult in
                if case .failure = completionResult, !didHandleValue {
                    completion?(true)
                }
            }, receiveValue: { [weak self] response in
                didHandleValue = true
                let status = response.accountStatus?.lowercased() ?? ""
                let isPending = (status == "pending" || status == "under_review" || status == "pending_review")
                self?.isAccountPending = isPending
                self?.accountPendingMessage = response.message ?? ""
                self?.defaults.setUserDefaultsString(value: status, key: .sellerStatus)
                completion?(isPending)
            })
            .store(in: &cancellables)
    }

    /// Logs out retailer, clears state, and redirects to LoginScreen
    public func performLogout() {
        let headers = defaults.authHeader
        LoginServiceManager().logoutRetailer(headers: headers)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)

        self.isAccountPending = false
        self.accountPendingMessage = ""
        defaults.resetUserData()
        defaults.setUserDefaultsString(value: "", key: .sellerStatus)
        CartManager.shared.clearCart()
        AppRootManager.shared.setRootView(view: LoginScreen())
    }

    /// Primary check-status call that checks maintenance mode, force update, soft update, and loads charges & customer support.
    public func checkStatus(completion: ((RetailerCheckStatusData?) -> Void)? = nil) {
        guard !isCheckingStatus else { return }
        isCheckingStatus = true

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let params: [String: Any] = [
            "app_version": appVersion,
            "device_type": "ios"
        ]

        let headers = defaults.authHeader

        NetworkServiceManager.shared.request(
            APIRouter.retailerCheckStatus,
            params: params,
            headers: headers
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completionResult in
            self?.isCheckingStatus = false
            if case .failure = completionResult {
                completion?(nil)
            }
        }, receiveValue: { [weak self] (response: RetailerCheckStatusResponse) in
            guard let self = self, let data = response.data else {
                completion?(nil)
                return
            }
            self.handleCheckStatusData(data)
            completion?(data)
        })
        .store(in: &cancellables)
    }

    private func handleCheckStatusData(_ data: RetailerCheckStatusData) {
        self.charges = data.charges
        self.accountDetails = data.accountDetails

        if let number = data.customerSupport?.number, !number.isEmpty {
            self.customerSupportNumber = number
            self.defaults.setUserDefaultsString(value: number, key: .customerSupportPhone)
        }

        // Maintenance Mode
        self.isMaintenance = data.isMaintenance == true

        // Force / Soft Update
        self.isForceUpdate = data.forceUpdate == true
        self.isSoftUpdate = (data.needsUpdate == true || data.hasNewVersion == true) && !self.isForceUpdate
        self.updateUrl = data.updateUrl ?? ""
        self.updateMessage = data.updateMessage ?? "A new version of the app is available."
    }
}
