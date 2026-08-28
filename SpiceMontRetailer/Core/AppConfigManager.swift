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

    private let defaults = UserDefaultManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        let cachedSupport = defaults.getUserDefaultsString(key: .customerSupportPhone)
        if !cachedSupport.isEmpty {
            self.customerSupportNumber = cachedSupport
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
