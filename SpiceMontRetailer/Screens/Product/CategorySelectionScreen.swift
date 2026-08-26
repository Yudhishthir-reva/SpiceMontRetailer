//
//  CategorySelectionScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

struct CategorySelectionScreen: View {
    let brandName: String
    var brandId: Int? = nil

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cartManager = CartManager.shared
    @State private var showCart: Bool = false

    @State private var categories: [SpiceCategory] = []
    @State private var isLoading: Bool = false
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let service = HomeServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var displayCategories: [SpiceCategory] {
        categories
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.spiceBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Step Subheader
                HStack {
                    Text("Select Category")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                    Spacer()
                    Text("Step 2 of 3")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.spicePrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.spicePrimaryLight)
                        .cornerRadius(6)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 6)

                if isLoading && categories.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(0..<6, id: \.self) { _ in
                                SpiceSkeletonBox(height: 120, cornerRadius: 14)
                            }
                        }
                        .padding(16)
                    }
                } else if displayCategories.isEmpty {
                    VStack {
                        Spacer()
                        SpiceEmptyStateView(
                            title: "No Categories Found",
                            message: "No product categories are available for this brand.",
                            buttonTitle: "Retry"
                        ) {
                            loadCategories()
                        }
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(displayCategories) { cat in
                                NavigationLink(
                                    destination: ProductListingView(
                                        brandName: brandName,
                                        categoryName: cat.name ?? "Category",
                                        brandId: brandId,
                                        categoryId: cat.id
                                    )
                                ) {
                                    categoryCard(cat)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                        .padding(.bottom, cartManager.cartCount > 0 ? 80 : 20)
                    }
                    .refreshable {
                        loadCategories()
                        cartManager.fetchCart()
                    }
                }
            }

            // MARK: - Floating Bottom Cart Pill Bar
            floatingCartBar
        }
        .navigationTitle(brandName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            loadCategories()
            cartManager.fetchCart()
        }
        .sheet(isPresented: $showCart) {
            NavigationStack { CartScreen() }
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Category 3-Column Card
    private func categoryCard(_ cat: SpiceCategory) -> some View {
        VStack(spacing: 0) {
            // Category Image Box
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#F2F5F3"))

                if let img = cat.image, !img.isEmpty {
                    RemoteImage(url: img)
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 72)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [Color(hex: "#56CCF2"), Color(hex: "#2F80ED")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(
                            Image(systemName: "photo.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
            }
            .frame(height: 72)
            .padding(6)

            // Category Name Label
            Text((cat.name ?? "Category").uppercased())
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(Color.spiceInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 6)
                .padding(.top, 4)
                .padding(.bottom, 10)
        }
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Floating Bottom Cart Pill Bar
    @ViewBuilder
    private var floatingCartBar: some View {
        if cartManager.cartCount > 0 {
            VStack(spacing: 0) {
                Button(action: {
                    showCart = true
                }) {
                    HStack {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 14, weight: .bold))

                        Text("\(cartManager.cartCount) \(cartManager.cartCount == 1 ? "unit" : "units") in cart")
                            .font(.system(size: 13.5, weight: .heavy))

                        Spacer()

                        Text("VIEW CART")
                            .font(.system(size: 12.5, weight: .heavy))
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

    // MARK: - Service Call
    private func loadCategories() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader
        var params: [String: Any] = [:]
        if let bId = brandId {
            params["brand_id"] = bId
        }

        service.fetchCategoryList(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                }
            } receiveValue: { response in
                self.categories = response.categories ?? []
            }
            .store(in: &cancellables)
    }
}
