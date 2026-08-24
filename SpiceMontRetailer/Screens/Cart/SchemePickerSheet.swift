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

    @State private var schemes: [RetailerOfferScheme] = []
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
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Available Schemes")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                        Text("Select a wholesale scheme to apply to this order")
                            .font(.system(size: 11, weight: .medium))
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

                if isLoading {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                            .tint(Color.spicePrimary)
                        Text("Fetching available schemes...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.spiceBackground)
                } else if schemes.isEmpty {
                    VStack(spacing: 10) {
                        Spacer()
                        Image(systemName: "tag.slash")
                            .font(.system(size: 40))
                            .foregroundColor(Color.spiceMuted.opacity(0.4))
                        Text("No Schemes Available")
                            .font(.system(size: 14.5, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                        Text("There are no active wholesale schemes for your account currently.")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Color.spiceBackground)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(schemes) { scheme in
                                schemeCard(scheme)
                            }
                        }
                        .padding(16)
                    }
                    .background(Color.spiceBackground)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadAvailableSchemes()
            }
            .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
                AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
            }, onTap: nil, completion: nil)
        }
    }

    // MARK: - Scheme Card
    private func schemeCard(_ scheme: RetailerOfferScheme) -> some View {
        let minVal = scheme.minOrderValue ?? 0
        let isEligible = cartTotal >= minVal
        let isApplied = (appliedSchemeId == scheme.id) || (cartManager.appliedOffer?.id == scheme.id)
        let shortfall = max(0, minVal - cartTotal)

        return SpiceCard(
            backgroundColor: isApplied ? Color.spicePrimaryLight.opacity(0.3) : Color.white,
            borderColor: isApplied ? Color.spicePrimary : (isEligible ? Color.spiceCardBorder : Color.spiceCardBorder.opacity(0.6))
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(scheme.title ?? "Wholesale Scheme")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                        Text(scheme.description ?? "")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                            .lineLimit(2)
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

                // Minimum Order & Shortfall Info
                HStack {
                    if minVal > 0 {
                        Text("Min Order: ₹\(String(format: "%.0f", minVal))")
                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.spiceMuted)
                    }

                    Spacer()

                    if isApplied {
                        Button(action: {
                            removeScheme()
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
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(Color.spiceAmber)
                    }
                }
            }
        }
    }

    // MARK: - Actions
    private func loadAvailableSchemes() {
        isLoading = true
        let headers = defaults.authHeader

        orderService.fetchAvailableOffers(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [self] comp in
                self.isLoading = false
            } receiveValue: { [self] response in
                self.schemes = response.data?.schemes ?? []
            }
            .store(in: &cancellables)
    }

    private func applyScheme(_ scheme: RetailerOfferScheme) {
        guard let sId = scheme.id else { return }
        isApplying = true
        let headers = defaults.authHeader

        orderService.applyOffer(params: sId, headers: headers)
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

    private func removeScheme() {
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
