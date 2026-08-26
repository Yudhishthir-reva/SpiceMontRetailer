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

    @Published var homeResponse: RetailerHomeResponse?
    @Published var retailerWidgets: [RetailerWidget] = []
    @Published var retailerBanners: [RetailerBannerItem] = []

    // Retailer Profile Fields
    @Published var greeting: String = ""
    @Published var sellerName: String = ""
    @Published var shopName: String = ""
    @Published var address: String = ""
    @Published var sellerId: String = ""
    @Published var profilePic: String = ""

    // Contact info
    @Published var salesmanName: String = ""
    @Published var salesmanPhone: String = ""
    @Published var customerSupportPhone: String = ""

    // Account status
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

    init() {
        loadCachedUser()
    }

    private func loadCachedUser() {
        let cachedName = defaults.getUserDefaultsString(key: .userName)
        if !cachedName.isEmpty { sellerName = cachedName }

        let cachedShop = defaults.getUserDefaultsString(key: .shopName)
        if !cachedShop.isEmpty { shopName = cachedShop }

        let cachedAddr = defaults.getUserDefaultsString(key: .shopAddress)
        if !cachedAddr.isEmpty { address = cachedAddr }

        let cachedSellerId = defaults.getUserDefaultsString(key: .sellerId)
        if !cachedSellerId.isEmpty { sellerId = cachedSellerId }

        let cachedPic = defaults.getUserDefaultsString(key: .profilePic)
        if !cachedPic.isEmpty { profilePic = cachedPic }

        let cachedGreeting = defaults.getUserDefaultsString(key: .greeting)
        if !cachedGreeting.isEmpty { greeting = cachedGreeting }

        let cachedSalesman = defaults.getUserDefaultsString(key: .salesmanName)
        if !cachedSalesman.isEmpty { salesmanName = cachedSalesman }

        let cachedSalesmanPhone = defaults.getUserDefaultsString(key: .salesmanPhone)
        if !cachedSalesmanPhone.isEmpty { salesmanPhone = cachedSalesmanPhone }

        let cachedSupport = defaults.getUserDefaultsString(key: .customerSupportPhone)
        if !cachedSupport.isEmpty { customerSupportPhone = cachedSupport }
    }

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
                self.homeResponse = response
                self.isAccountPending = (response.accountStatus?.lowercased() == "pending")
                self.accountPendingMessage = response.message ?? ""

                // 1. Process User Profile
                if let g = response.greeting ?? response.user?.greeting, !g.isEmpty {
                    self.greeting = g
                    self.defaults.setUserDefaultsString(value: g, key: .greeting)
                }

                if let name = response.sellerName ?? response.user?.name, !name.isEmpty {
                    self.sellerName = name
                    self.defaults.setUserDefaultsString(value: name, key: .userName)
                }

                if let shop = response.shopName ?? response.user?.shopName, !shop.isEmpty {
                    self.shopName = shop
                    self.defaults.setUserDefaultsString(value: shop, key: .shopName)
                }

                if let addr = response.address ?? response.user?.address, !addr.isEmpty {
                    self.address = addr
                    self.defaults.setUserDefaultsString(value: addr, key: .shopAddress)
                }

                if let sid = response.user?.sellerId, !sid.isEmpty {
                    self.sellerId = sid
                    self.defaults.setUserDefaultsString(value: sid, key: .sellerId)
                }

                if let pic = response.user?.profilePic, !pic.isEmpty {
                    self.profilePic = pic
                    self.defaults.setUserDefaultsString(value: pic, key: .profilePic)
                }

                // 2. Process Dynamic Widgets
                if let rawWidgets = response.widgets {
                    // Sort widgets by sort_order if provided
                    self.retailerWidgets = rawWidgets.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }

                    // Extract child widgets for quick access
                    for w in self.retailerWidgets {
                        if let s = w.salesman {
                            if let sName = s.name, !sName.isEmpty {
                                self.salesmanName = sName
                                self.defaults.setUserDefaultsString(value: sName, key: .salesmanName)
                            }
                            if let sContact = s.contact ?? s.phone ?? s.mobile, !sContact.isEmpty {
                                self.salesmanPhone = sContact
                                self.defaults.setUserDefaultsString(value: sContact, key: .salesmanPhone)
                            }
                        }
                        if let cs = w.customerSupport, let contact = cs.contact, !contact.isEmpty {
                            self.customerSupportPhone = contact
                            self.defaults.setUserDefaultsString(value: contact, key: .customerSupportPhone)
                        }
                        if w.type == "banner", let bList = w.banners {
                            self.retailerBanners = bList
                        }
                    }
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
                let wList = response.widgets ?? []
                self?.widgets = wList
                for w in wList {
                    if let prods = w.products {
                        for prod in prods {
                            if let pId = prod.id {
                                if let avl = prod.availableQuantity { CartManager.shared.registerStock(productId: pId, stock: avl) }
                                if let variants = prod.variants {
                                    for v in variants {
                                        if let vAvl = v.availableQuantity { CartManager.shared.registerStock(productId: pId, variantId: v.id, variantName: v.unit, stock: vAvl) }
                                    }
                                }
                            }
                        }
                    }
                }
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
