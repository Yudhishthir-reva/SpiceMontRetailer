//
//  BrandSelectionScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

struct BrandSelectionScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cartManager = CartManager.shared
    @State private var showCart: Bool = false

    @State private var brands: [Brand] = []
    @State private var isLoading: Bool = false
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let service = HomeServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var displayedBrands: [Brand] {
        return brands
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.spiceBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    // MARK: - Step Subheader
                    HStack {
                        Text("All Brands")
                            .font(.appFont(size: 15, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                        Spacer()
                        Text("Step 1 of 3")
                            .font(.appFont(size: 12, weight: .bold))
                            .foregroundColor(Color.spicePrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.spicePrimaryLight)
                            .cornerRadius(6)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 4)

                    // MARK: - 2-Column Brand Grid
                    if isLoading && brands.isEmpty {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 14),
                                GridItem(.flexible(), spacing: 14)
                            ],
                            spacing: 14
                        ) {
                            ForEach(0..<6, id: \.self) { _ in
                                SpiceSkeletonBox(height: 140, cornerRadius: 16)
                            }
                        }
                    } else if displayedBrands.isEmpty {
                        SpiceEmptyStateView(
                            title: "No Brands Available",
                            message: "Unable to load brands. Please check your connection and try again.",
                            buttonTitle: "Retry"
                        ) {
                            loadBrands()
                        }
                        .padding(.top, 40)
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 14),
                                GridItem(.flexible(), spacing: 14)
                            ],
                            spacing: 14
                        ) {
                            ForEach(displayedBrands) { brand in
                                NavigationLink(destination: CategorySelectionScreen(brandName: brand.name ?? "Brand", brandId: brand.id)) {
                                    VStack(spacing: 8) {
                                        // Image Box
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(hex: "#EEF2EF"))

                                            if let img = brand.image, !img.isEmpty {
                                                RemoteImage(url: img)
                                                    .scaledToFit()
                                                    .frame(height: 70)
                                                    .padding(8)
                                            } else if let name = brand.name?.lowercased(), name.contains("spice monk") {
                                                Image("spice_monk_logo")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 58, height: 58)
                                            } else {
                                                Image(systemName: "photo.slash")
                                                    .font(.appFont(size: 36, weight: .light))
                                                    .foregroundColor(Color.spiceMuted.opacity(0.4))
                                            }
                                        }
                                        .frame(height: 104)

                                        // Brand Name
                                        Text(brand.name ?? "")
                                            .font(.appFont(size: 13.5, weight: .bold))
                                            .foregroundColor(Color.spiceInk)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(1)
                                            .padding(.bottom, 6)
                                    }
                                    .padding(8)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer(minLength: cartManager.cartCount > 0 ? 80 : 30)
                }
                .padding(.horizontal, 16)
            }
            .refreshable {
                loadBrands()
                cartManager.fetchCart()
            }

            // MARK: - Floating Bottom Cart Bar
            if cartManager.cartCount > 0 {
                VStack(spacing: 0) {
                    Button(action: {
                        showCart = true
                    }) {
                        HStack {
                            Image(systemName: "cart.fill")
                                .font(.appFont(size: 14, weight: .bold))

                            Text("\(cartManager.cartCount) \(cartManager.cartCount == 1 ? "unit" : "units") in cart")
                                .font(.appFont(size: 13.5, weight: .heavy))

                            Spacer()

                            Text("VIEW CART")
                                .font(.appFont(size: 12.5, weight: .heavy))
                                .tracking(0.5)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(Color.spicePrimary)
                        .cornerRadius(12)
                        .shadow(color: Color.spicePrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .padding(.top, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.spiceBackground.opacity(0), Color.spiceBackground],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: cartManager.cartCount > 0)
        .navigationTitle("Select Brand")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    loadBrands()
                    cartManager.fetchCart()
                }) {
                    Text("Refresh")
                        .font(.appFont(size: 13.5, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                }
            }
        }
        .onAppear {
            loadBrands()
            cartManager.fetchCart()
        }
        .sheet(isPresented: $showCart) {
            NavigationStack { CartScreen() }
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    private func loadBrands() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader

        service.fetchBrandList(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    isShowToast = true
                }
            } receiveValue: { response in
                self.brands = response.brands ?? []
            }
            .store(in: &cancellables)
    }
}
