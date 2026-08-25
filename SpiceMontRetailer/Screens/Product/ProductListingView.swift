//
//  ProductListingView.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

struct ProductListingView: View {
    let brandName: String
    let categoryName: String
    var brandId: Int? = nil
    var categoryId: Int? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "Price ↑"
    @ObservedObject private var cartManager = CartManager.shared
    @State private var showCart: Bool = false
    @State private var selectedPackSizeProduct: Product? = nil

    @State private var products: [Product] = []
    @State private var isLoading: Bool = false
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let filterChips = ["Admin Priority", "Best Selling", "Price ↑", "Price ↓", "Discount"]
    private let productService = ProductServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var displayProducts: [Product] {
        var list = products
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            list = list.filter {
                ($0.name?.localizedCaseInsensitiveContains(searchText) == true) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) == true)
            }
        }

        switch selectedFilter {
        case "Price ↑":
            list.sort { (Double($0.price ?? "0") ?? 0) < (Double($1.price ?? "0") ?? 0) }
        case "Price ↓":
            list.sort { (Double($0.price ?? "0") ?? 0) > (Double($1.price ?? "0") ?? 0) }
        case "Discount":
            list.sort { (Double($0.discountPercentage ?? "0") ?? 0) > (Double($1.discountPercentage ?? "0") ?? 0) }
        default:
            break
        }

        return list
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top Bar
                HStack(alignment: .center, spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.spiceInk)
                            .padding(4)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(categoryName)
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Text("\(brandName) · \(displayProducts.count) products")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(Color.white)
                .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

                // MARK: - Search Bar & Filter Chips
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.spiceMuted)
                            .font(.system(size: 14, weight: .semibold))

                        TextField("Search products", text: $searchText)
                            .font(.system(size: 13.5, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))

                    // Filter Chips Row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filterChips, id: \.self) { chip in
                                let isSelected = selectedFilter == chip
                                Button(action: {
                                    selectedFilter = chip
                                }) {
                                    Text(chip)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(isSelected ? .white : Color.spiceInk)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(isSelected ? Color.spicePrimary : Color.white)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(isSelected ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.spiceBackground)

                if isLoading && products.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(0..<6, id: \.self) { _ in
                                SpiceSkeletonBox(height: 260, cornerRadius: 16)
                            }
                        }
                        .padding(16)
                    }
                } else if displayProducts.isEmpty {
                    VStack(spacing: 14) {
                        Spacer()
                        Image(systemName: "cube.box")
                            .font(.system(size: 44))
                            .foregroundColor(Color.spiceMuted)

                        Text("No Products Available")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Text("No products found in this category right now.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(displayProducts) { item in
                                productCard(item)
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 80)
                    }
                    .refreshable {
                        loadProducts()
                    }
                }
            }

            // MARK: - Floating Bottom Cart Pill Bar
            floatingCartBar
        }
        .navigationBarHidden(true)
        .onAppear {
            loadProducts()
            cartManager.fetchCart()
        }
        .sheet(item: $selectedPackSizeProduct) { product in
            PackSizeSelectionSheet(product: product)
        }
        .sheet(isPresented: $showCart) {
            NavigationStack { CartScreen() }
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Product Card (2-Column)
    private func productCard(_ product: Product) -> some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationLink(destination: ProductDetailScreen(productId: product.id ?? 1, initialProduct: product)) {
                VStack(alignment: .leading, spacing: 8) {
                    // Product Image & Discount Badge
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#F9FAF9"))

                        if let img = product.image, !img.isEmpty {
                            RemoteImage(url: img)
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 110)
                                .padding(8)
                        } else {
                            Image("spice_monk_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 80, maxHeight: 80)
                                .frame(maxWidth: .infinity, maxHeight: 110)
                        }

                        // Green Discount Pill Badge
                        if let discount = product.discountPercentage, !discount.isEmpty, discount != "0" {
                            Text("\(discount)% OFF")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.spicePrimary)
                                .cornerRadius(6)
                                .padding(8)
                        }
                    }
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.spiceCardBorder.opacity(0.6), lineWidth: 0.8)
                    )

                    // Product Name
                    Text(product.name ?? "Spice Powder")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 36, alignment: .topLeading)

                    // Pricing Row
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("₹\(product.price ?? "24.00")")
                                    .font(.system(size: 14.5, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color.spiceInk)

                                if let mrp = product.mrp, !mrp.isEmpty {
                                    Text("₹\(mrp)")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(Color.spiceMuted)
                                        .strikethrough()
                                }
                            }

                            if let unit = product.unit, !unit.isEmpty {
                                Text(unit)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.spiceMuted)
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 2)
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Dynamic ADD / Active Quantity Pill Button
            let inCartCount = cartManager.quantityForProduct(product.id ?? 1)

            Button(action: {
                selectedPackSizeProduct = product
            }) {
                if inCartCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                        Text("\(inCartCount)")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    }
                    .foregroundColor(.white)
                    .frame(width: 58, height: 32)
                    .background(Color.spicePrimary)
                    .cornerRadius(8)
                } else {
                    Text("ADD")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color(hex: "#167444"))
                        .frame(width: 58, height: 32)
                        .background(Color(hex: "#EBF7EE"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#D2EBD9"), lineWidth: 1)
                        )
                }
            }
            .buttonStyle(.plain)
            .padding(10)
        }
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
    private func loadProducts() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader
        var params: [String: Any] = [:]
        if let bId = brandId { params["brand_id"] = bId }
        if let cId = categoryId { params["category_id"] = cId }

        productService.fetchProductList(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                }
            } receiveValue: { response in
                self.products = response.dataPage?.products ?? []
            }
            .store(in: &cancellables)
    }
}
