//
//  SchemePickerSheet.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

struct SchemePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cartManager = CartManager.shared
    
    let cartTotal: Double
    let appliedSchemeId: Int?
    var onSchemeSelected: ((RetailerOfferScheme) -> Void)?
    var onSchemeRemoved: (() -> Void)?

    @State private var selectedTab: Int = 0 // 0: Schemes, 1: Quantity Slabs
    @State private var schemes: [RetailerOfferScheme] = []
    @State private var slabs: [RetailerQuantitySlab] = []
    @State private var isLoading: Bool = false
    @State private var isApplying: Bool = false
    @State private var toastMessage: String = ""
    @State private var isShowToast: Bool = false

    private let orderService = OrderServiceManager()
    private let defaults = UserDefaultManager.shared
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Offers & Wholesale Schemes")
                            .font(.system(size: 16.5, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                        Text("Select a scheme or quantity slab to apply to your cart")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.spiceMuted.opacity(0.6))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

                // MARK: - Segmented Tab Selector
                HStack(spacing: 8) {
                    tabButton(title: "Order Schemes (\(schemes.count))", index: 0)
                    tabButton(title: "Quantity Slabs (\(slabs.count))", index: 1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
                .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

                if isLoading {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                            .tint(Color.spicePrimary)
                        Text("Fetching available offers & schemes...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.spiceBackground)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if selectedTab == 0 {
                                if schemes.isEmpty {
                                    emptyOffersView(message: "No order schemes currently available.")
                                } else {
                                    ForEach(schemes) { scheme in
                                        schemeCard(scheme)
                                    }
                                }
                            } else {
                                if slabs.isEmpty {
                                    emptyOffersView(message: "No quantity slabs currently available.")
                                } else {
                                    ForEach(slabs) { slab in
                                        slabCard(slab)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                    .background(Color.spiceBackground)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadAvailableOffers()
            }
            .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
                AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
            }, onTap: nil, completion: nil)
        }
    }

    // MARK: - Tab Button
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            Text(title)
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(selectedTab == index ? Color.spicePrimary : Color.spiceMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedTab == index ? Color.spicePrimaryLight.opacity(0.4) : Color(hex: "#F4F6F4"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selectedTab == index ? Color.spicePrimary.opacity(0.4) : Color.clear, lineWidth: 1)
                )
        }
    }

    // MARK: - Scheme Card (Order Value Based)
    private func schemeCard(_ scheme: RetailerOfferScheme) -> some View {
        let minVal = scheme.minOrderValue ?? 0
        let isEligible = scheme.eligible ?? (cartTotal >= minVal)
        let isApplied = (appliedSchemeId == scheme.id) || (cartManager.appliedOffer?.id == scheme.id)
        let shortfall = max(0, minVal - cartTotal)

        return SpiceCard(
            backgroundColor: isApplied ? Color.spicePrimaryLight.opacity(0.3) : Color.white,
            borderColor: isApplied ? Color.spicePrimary : (isEligible ? Color.spiceCardBorder : Color.spiceCardBorder.opacity(0.6))
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(scheme.title ?? "Order Scheme")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        if let desc = scheme.description, !desc.isEmpty {
                            Text(desc)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    if isApplied {
                        SpiceStatusBadge(status: "APPLIED")
                    } else if isEligible {
                        SpiceStatusBadge(status: "QUALIFIED")
                    } else {
                        SpiceStatusBadge(status: "LOCKED")
                    }
                }

                Divider().padding(.vertical, 2)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if minVal > 0 {
                            Text("Min Order: ₹\(String(format: "%.0f", minVal))")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color.spiceMuted)
                        }
                        if let discAmt = scheme.discountAmount, discAmt > 0 {
                            Text("Save ₹\(String(format: "%.2f", discAmt))")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(Color.spicePrimary)
                        }
                    }

                    Spacer()

                    if isApplied {
                        Button(action: {
                            removeOffer()
                        }) {
                            Text("Remove")
                                .font(.system(size: 11.5, weight: .heavy))
                                .foregroundColor(Color.spiceDue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.spiceDueLight)
                                .cornerRadius(6)
                        }
                    } else if isEligible {
                        Button(action: {
                            applyScheme(scheme)
                        }) {
                            Text("Apply")
                                .font(.system(size: 11.5, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.spicePrimary)
                                .cornerRadius(6)
                        }
                        .disabled(isApplying)
                    } else {
                        Text("Add ₹\(String(format: "%.0f", shortfall)) more")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.spiceAmber)
                    }
                }
            }
        }
    }

    // MARK: - Slab Card (Quantity Based)
    private func slabCard(_ slab: RetailerQuantitySlab) -> some View {
        let minQty = slab.minQty ?? 0
        let isEligible = slab.eligible ?? (cartManager.cartCount >= minQty)
        let isApplied = (appliedSchemeId == slab.id) || (cartManager.appliedOffer?.id == slab.id)

        return SpiceCard(
            backgroundColor: isApplied ? Color.spicePrimaryLight.opacity(0.3) : Color.white,
            borderColor: isApplied ? Color.spicePrimary : (isEligible ? Color.spiceCardBorder : Color.spiceCardBorder.opacity(0.6))
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(slab.title ?? "Quantity Slab")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        if let gift = slab.giftDescription, !gift.isEmpty {
                            Text("🎁 Reward: \(gift)")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(Color.spicePrimary)
                        } else if let desc = slab.description, !desc.isEmpty {
                            Text(desc)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                        }
                    }

                    Spacer()

                    if isApplied {
                        SpiceStatusBadge(status: "APPLIED")
                    } else if isEligible {
                        SpiceStatusBadge(status: "QUALIFIED")
                    } else {
                        SpiceStatusBadge(status: "LOCKED")
                    }
                }

                Divider().padding(.vertical, 2)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if minQty > 0 {
                            Text("Min Quantity: \(minQty) units")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color.spiceMuted)
                        }
                        if let discAmt = slab.discountAmount, discAmt > 0 {
                            Text("Save ₹\(String(format: "%.2f", discAmt))")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(Color.spicePrimary)
                        }
                    }

                    Spacer()

                    if isApplied {
                        Button(action: {
                            removeOffer()
                        }) {
                            Text("Remove")
                                .font(.system(size: 11.5, weight: .heavy))
                                .foregroundColor(Color.spiceDue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.spiceDueLight)
                                .cornerRadius(6)
                        }
                    } else if isEligible {
                        Button(action: {
                            applySlab(slab)
                        }) {
                            Text("Apply")
                                .font(.system(size: 11.5, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.spicePrimary)
                                .cornerRadius(6)
                        }
                        .disabled(isApplying)
                    } else {
                        Text("Need \(minQty) units")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.spiceAmber)
                    }
                }
            }
        }
    }

    private func emptyOffersView(message: String) -> some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 30)
            Image(systemName: "tag.slash")
                .font(.system(size: 36))
                .foregroundColor(Color.spiceMuted.opacity(0.4))
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.spiceMuted)
                .multilineTextAlignment(.center)
            Spacer().frame(height: 30)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions
    private func loadAvailableOffers() {
        isLoading = true
        let headers = defaults.authHeader

        orderService.fetchAvailableOffers(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [self] comp in
                self.isLoading = false
            } receiveValue: { [self] response in
                self.schemes = response.data?.schemes ?? []
                self.slabs = response.data?.slabs ?? []
            }
            .store(in: &cancellables)
    }

    private func applyScheme(_ scheme: RetailerOfferScheme) {
        guard let sId = scheme.id else { return }
        isApplying = true
        let headers = defaults.authHeader
        let params: [String: Any] = [
            "promotion_id": sId,
            "offer_id": sId,
            "scheme_id": sId,
            "type": "scheme"
        ]

        orderService.applyOffer(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [self] comp in
                self.isApplying = false
                if case .failure(let error) = comp {
                    self.toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    self.isShowToast = true
                }
            } receiveValue: { [self] response in
                if response.status == true {
                    self.cartManager.fetchCart()
                    self.onSchemeSelected?(scheme)
                    self.dismiss()
                } else {
                    self.toastMessage = response.message ?? "Failed to apply scheme"
                    self.isShowToast = true
                }
            }
            .store(in: &cancellables)
    }

    private func applySlab(_ slab: RetailerQuantitySlab) {
        guard let sId = slab.id else { return }
        isApplying = true
        let headers = defaults.authHeader
        let params: [String: Any] = [
            "promotion_id": sId,
            "offer_id": sId,
            "slab_id": sId,
            "type": "quantity_slab"
        ]

        orderService.applyOffer(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [self] comp in
                self.isApplying = false
                if case .failure(let error) = comp {
                    self.toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    self.isShowToast = true
                }
            } receiveValue: { [self] response in
                if response.status == true {
                    self.cartManager.fetchCart()
                    self.dismiss()
                } else {
                    self.toastMessage = response.message ?? "Failed to apply slab"
                    self.isShowToast = true
                }
            }
            .store(in: &cancellables)
    }

    private func removeOffer() {
        isApplying = true
        let headers = defaults.authHeader

        orderService.removeOffer(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [self] comp in
                self.isApplying = false
            } receiveValue: { [self] response in
                self.cartManager.fetchCart()
                self.onSchemeRemoved?()
                self.dismiss()
            }
            .store(in: &cancellables)
    }
}
