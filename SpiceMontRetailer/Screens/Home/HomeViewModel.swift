//
//  HomeViewModel.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import Foundation
import Combine
import SwiftUI

class HomeViewModel: ObservableObject {

    @Published var retailerWidgets: [RetailerWidget] = []
    @Published var retailerBanners: [RetailerBannerItem] = []
    @Published var isAccountPending = false
    @Published var accountPendingMessage = ""

    // Legacy fallback support
    @Published var banners: [Banner] = []
    @Published var categories: [SpiceCategory] = []
    @Published var widgets: [HomeWidget] = []

    @Published var isLoading = false
    @Published var isShowToast = false
    @Published var toastMessage = ""
    @Published var currentBannerIndex = 0

    private let service = HomeServiceManager()
    private let defaults = UserDefaultManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var bannerTimer: AnyCancellable?

    func loadHome() {
        isLoading = true
        let headers = defaults.authHeader

        service.fetchRetailerHome(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    // Try legacy format if retailer home fails
                    self?.loadLegacyHome()
                }
            } receiveValue: { [weak self] response in
                guard let self else { return }
                self.isAccountPending = (response.accountStatus?.lowercased() == "pending")
                self.accountPendingMessage = response.message ?? ""
                self.retailerWidgets = response.widgets ?? []

                // Extract retailer banners
                if let bannerWidget = self.retailerWidgets.first(where: { $0.type == "banner" }) {
                    self.retailerBanners = bannerWidget.banners ?? []
                }
                self.startBannerAutoScroll()
            }
            .store(in: &cancellables)
    }

    private func loadLegacyHome() {
        let headers = defaults.authHeader
        service.fetchHome(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    self?.isShowToast = true
                }
            } receiveValue: { [weak self] response in
                self?.banners = response.banners ?? []
                self?.categories = response.categories ?? []
                self?.widgets = response.widgets ?? []
                self?.startBannerAutoScroll()
            }
            .store(in: &cancellables)
    }

    func startBannerAutoScroll() {
        bannerTimer?.cancel()
        let count = !retailerBanners.isEmpty ? retailerBanners.count : banners.count
        guard count > 1 else { return }
        bannerTimer = Timer.publish(every: 4, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let total = !self.retailerBanners.isEmpty ? self.retailerBanners.count : self.banners.count
                guard total > 0 else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.currentBannerIndex = (self.currentBannerIndex + 1) % total
                }
            }
    }

    func stopBannerAutoScroll() {
        bannerTimer?.cancel()
    }

    deinit {
        bannerTimer?.cancel()
    }
}
