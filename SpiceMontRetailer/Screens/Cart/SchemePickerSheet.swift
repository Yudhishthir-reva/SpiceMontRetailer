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
    var onSchemeApplied: ((RetailerAppliedOffer) -> Void)?
    var onSchemeRemoved: (() -> Void)?

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
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Available Offers")
                                .font(.appFont(size: 18, weight: .heavy))
                                .foregroundColor(Color.spiceInk)

                            Spacer()

                            Button(action: {
                                loadAvailableOffers()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.appFont(size: 15, weight: .bold))
                                    .foregroundColor(Color.spiceInk)
                                    .padding(4)
                            }
                        }

                        Text("One offer applies at a time. Pick the one worth most to you.")
                            .font(.appFont(size: 12.5, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 10)
                    .background(Color.white)

                    Divider().background(Color.spiceDivider.opacity(0.8))

                    if isLoading {
                        VStack(spacing: 12) {
                            Spacer()
                            ProgressView()
                                .tint(Color.spicePrimary)
                            Text("Loading available offers...")
                                .font(.appFont(size: 13, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                    } else if schemes.isEmpty && slabs.isEmpty {
                        VStack {
                            Spacer()
                            SpiceEmptyStateView(
                                title: "No Offers Available",
                                message: "There are no active schemes or quantity slabs right now.",
                                buttonTitle: "Refresh"
                            ) {
                                loadAvailableOffers()
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 14) {
                                // Currently Applied Offer Banner (if any)
                                if let applied = cartManager.appliedOffer {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("Applied Offer")
                                                .font(.appFont(size: 13.5, weight: .heavy))
                                                .foregroundColor(Color(hex: "#167444"))

                                            Spacer()

                                            Button(action: {
                                                handleRemoveOffer()
                                            }) {
                                                Text("Remove")
                                                    .font(.appFont(size: 12, weight: .bold))
                                                    .foregroundColor(Color.spicePrimary)
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        Text(applied.schemeTitle ?? "Offer Applied")
                                            .font(.appFont(size: 13, weight: .bold))
                                            .foregroundColor(Color.spiceInk)

                                        if let desc = applied.discountText, !desc.isEmpty {
                                            Text(desc)
                                                .font(.appFont(size: 12, weight: .medium))
                                                .foregroundColor(Color.spiceMuted)
                                        }
                                    }
                                    .padding(12)
                                    .background(Color(hex: "#EBF7EE"))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: "#D2EBD9"), lineWidth: 1)
                                    )
                                }

                                // Order Value Schemes
                                ForEach(schemes) { scheme in
                                    orderValueSchemeCard(scheme)
                                }

                                // Quantity Slabs
                                ForEach(slabs) { slab in
                                    quantitySlabCard(slab)
                                }

                                // View All Schemes Button at Bottom
                                Button(action: {
                                    dismiss()
                                }) {
                                    Text("View All Schemes")
                                        .font(.appFont(size: 14, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.spiceCardBorder, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)

                                Spacer(minLength: 20)
                            }
                            .padding(16)
                        }
                        .background(Color.white)
                    }
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
            .onAppear {
                loadAvailableOffers()
            }
            .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
                AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
            }, onTap: nil, completion: nil)
        }
        .background(Color.white)
    }

    // MARK: - Order Value Scheme Card (Exact Match)
    private func orderValueSchemeCard(_ scheme: RetailerOfferScheme) -> some View {
        let minVal = scheme.minOrderValue ?? 500.0
        let isEligible = scheme.eligible ?? (cartTotal >= minVal)
        let shortfall = max(0, minVal - cartTotal)
        let progress = min(1.0, cartTotal / minVal)

        return VStack(alignment: .leading, spacing: 8) {
            // Badges Row: [ ORDER VALUE ] [ LOCKED / ELIGIBLE ]
            HStack {
                Text("ORDER VALUE")
                    .font(.appFont(size: 10, weight: .heavy))
                    .foregroundColor(Color.spiceMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#F3F4F6"))
                    .cornerRadius(5)

                Spacer()

                if isEligible {
                    Text("ELIGIBLE")
                        .font(.appFont(size: 10, weight: .heavy))
                        .foregroundColor(Color(hex: "#167E46"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#E8F8EE"))
                        .cornerRadius(5)
                } else {
                    Text("LOCKED")
                        .font(.appFont(size: 10, weight: .heavy))
                        .foregroundColor(Color(hex: "#B87314"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#FEF4E6"))
                        .cornerRadius(5)
                }
            }

            // Scheme Title
            Text(scheme.title ?? "Special Offer")
                .font(.appFont(size: 14.5, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            // Minimum Requirement
            Text("Minimum order ₹\(Int(minVal))")
                .font(.appFont(size: 12, weight: .medium))
                .foregroundColor(Color.spiceMuted)

            if !isEligible {
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#F0DFC9"))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#8B5014"))
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.vertical, 1)

                // Unlock Shortfall Text
                Text("Add ₹\(String(format: "%.0f", shortfall)) more to activate this scheme")
                    .font(.appFont(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#8B5014"))
            } else {
                // Apply Offer Button
                Button(action: {
                    applyScheme(scheme)
                }) {
                    Text("Apply Offer")
                        .font(.appFont(size: 13, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.spicePrimary, lineWidth: 1.2)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Quantity Slab Card (Exact Match)
    private func quantitySlabCard(_ slab: RetailerQuantitySlab) -> some View {
        let minQty = slab.minQty ?? 10
        let currentQty = cartManager.cartCount
        let isEligible = slab.eligible ?? (currentQty >= minQty)
        let shortfallUnits = max(0, minQty - currentQty)
        let progress = min(1.0, Double(currentQty) / Double(minQty))

        return VStack(alignment: .leading, spacing: 8) {
            // Badges Row: [ QUANTITY SLAB ] [ LOCKED / ELIGIBLE ]
            HStack {
                Text("QUANTITY SLAB")
                    .font(.appFont(size: 10, weight: .heavy))
                    .foregroundColor(Color.spiceMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#F3F4F6"))
                    .cornerRadius(5)

                Spacer()

                if isEligible {
                    Text("ELIGIBLE")
                        .font(.appFont(size: 10, weight: .heavy))
                        .foregroundColor(Color(hex: "#167E46"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#E8F8EE"))
                        .cornerRadius(5)
                } else {
                    Text("LOCKED")
                        .font(.appFont(size: 10, weight: .heavy))
                        .foregroundColor(Color(hex: "#B87314"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#FEF4E6"))
                        .cornerRadius(5)
                }
            }

            // Slab Title
            Text(slab.title ?? "Quantity Offer")
                .font(.appFont(size: 14.5, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            // Minimum Requirement
            Text("Minimum \(minQty) units")
                .font(.appFont(size: 12, weight: .medium))
                .foregroundColor(Color.spiceMuted)

            if !isEligible {
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#F0DFC9"))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#8B5014"))
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.vertical, 1)

                // Unlock Shortfall Text
                Text("Add \(shortfallUnits) more units to unlock")
                    .font(.appFont(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#8B5014"))

                if let gift = slab.giftDescription ?? slab.description, !gift.isEmpty {
                    Text("Gift: \(gift)")
                        .font(.appFont(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#167444"))
                }
            } else {
                // Reward Text
                if let gift = slab.giftDescription ?? slab.description, !gift.isEmpty {
                    Text("You get \(gift)")
                        .font(.appFont(size: 12.5, weight: .bold))
                        .foregroundColor(Color(hex: "#167444"))
                }

                // Apply Offer Button
                Button(action: {
                    applySlab(slab)
                }) {
                    Text("Apply Offer")
                        .font(.appFont(size: 13, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.spicePrimary, lineWidth: 1.2)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Actions
    private func applyScheme(_ scheme: RetailerOfferScheme) {
        guard let pId = scheme.id else { return }
        isApplying = true
        let headers = defaults.authHeader
        let params: [String: Any] = ["promotion_id": pId]

        orderService.applyOffer(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isApplying = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    isShowToast = true
                }
            } receiveValue: { response in
                if response.status == true {
                    let d = response.data
                    let appliedOffer = RetailerAppliedOffer(
                        type: d?.rewardType ?? scheme.type,
                        id: d?.offerId ?? pId,
                        title: d?.offerTitle ?? scheme.title,
                        discountAmount: d?.discountAmount ?? scheme.discountAmount ?? 0.0,
                        giftDescription: d?.giftDescription,
                        finalAmount: d?.finalAmount,
                        minOrderValue: scheme.minOrderValue
                    )
                    cartManager.applyOfferResult(appliedOffer)
                    onSchemeSelected?(scheme)
                    onSchemeApplied?(appliedOffer)
                    dismiss()
                } else {
                    toastMessage = response.message ?? "Failed to apply offer"
                    isShowToast = true
                }
            }
            .store(in: &cancellables)
    }

    private func applySlab(_ slab: RetailerQuantitySlab) {
        guard let pId = slab.id else { return }
        isApplying = true
        let headers = defaults.authHeader
        let params: [String: Any] = ["promotion_id": pId]

        orderService.applyOffer(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isApplying = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    isShowToast = true
                }
            } receiveValue: { response in
                if response.status == true {
                    let d = response.data
                    let appliedOffer = RetailerAppliedOffer(
                        type: d?.rewardType ?? slab.type,
                        id: d?.offerId ?? pId,
                        title: d?.offerTitle ?? slab.title,
                        discountAmount: d?.discountAmount ?? slab.discountAmount ?? 0.0,
                        giftDescription: d?.giftDescription ?? slab.giftDescription,
                        finalAmount: d?.finalAmount,
                        minQty: slab.minQty
                    )
                    cartManager.applyOfferResult(appliedOffer)
                    onSchemeApplied?(appliedOffer)
                    dismiss()
                } else {
                    toastMessage = response.message ?? "Failed to apply offer"
                    isShowToast = true
                }
            }
            .store(in: &cancellables)
    }

    private func loadAvailableOffers() {
        isLoading = true
        let headers = defaults.authHeader

        orderService.fetchAvailableOffers(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
            } receiveValue: { response in
                if response.status == true {
                    self.schemes = response.data?.schemes ?? []
                    self.slabs = response.data?.slabs ?? []
                    cartManager.applyOffersCartTotal(response.cartTotal)
                }
            }
            .store(in: &cancellables)
    }

    private func handleRemoveOffer() {
        let headers = defaults.authHeader
        orderService.removeOffer(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { response in
                cartManager.appliedOffer = nil
                toastMessage = response.message ?? "Promotion remove ho gayi"
                isShowToast = true
                onSchemeRemoved?()
                loadAvailableOffers()
            }
            .store(in: &cancellables)
    }
}
