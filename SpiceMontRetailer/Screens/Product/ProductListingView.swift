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
    @State private var selectedFilter: String = "Default"
    @ObservedObject private var cartManager = CartManager.shared
    @State private var showCart: Bool = false
    @State private var selectedPackSizeProduct: Product? = nil

    @State private var products: [Product] = []
    @State private var isLoading: Bool = false
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let filterChips = ["Default", "Best Selling", "Price ↑", "Price ↓", "Discount"]
    private let productService = ProductServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
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
                // MARK: - Search & Filter Subheader
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.spiceMuted)
                            .font(.appFont(size: 14, weight: .semibold))

                        TextField("Search in \(categoryName)...", text: $searchText)
                            .font(.appFont(size: 13, weight: .medium))
                            .foregroundColor(Color.black)
                            .tint(Color.spicePrimary)

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.spiceMuted)
                                    .font(.appFont(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.spiceCardBorder, lineWidth: 1)
                    )

                    // Filter Chips Row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filterChips, id: \.self) { chip in
                                let isSelected = selectedFilter == chip
                                Button(action: {
                                    selectedFilter = chip
                                }) {
                                    Text(chip)
                                        .font(.appFont(size: 11.5, weight: .bold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color.spicePrimary : Color.white)
                                        .foregroundColor(isSelected ? .white : Color.spiceInk)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
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

                // MARK: - Product Grid (2 Columns)
                if isLoading && products.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                            .tint(Color.spicePrimary)
                        Text("Loading products...")
                            .font(.appFont(size: 12.5, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if displayProducts.isEmpty {
                    VStack {
                        Spacer()
                        SpiceEmptyStateView(
                            title: "No Products Found",
                            message: "No products available in this category.",
                            buttonTitle: "Refresh"
                        ) {
                            loadProducts()
                        }
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(displayProducts) { item in
                                productCard(item)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, 80)
                    }
                    .refreshable {
                        loadProducts()
                    }
                }
            }

            // MARK: - Floating Bottom Cart Bar
            floatingCartBar
        }
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
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

    // MARK: - Product Card (Exact Match to Screenshot)
    private func productCard(_ product: Product) -> some View {
        let inCartCount = cartManager.quantityForProduct(product.id ?? 1)

        return VStack(alignment: .leading, spacing: 6) {
            // Product Hero Image Box
            NavigationLink(destination: ProductDetailScreen(productId: product.id ?? 1, initialProduct: product)) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "#F8F9FA"))

                    if let img = product.image, !img.isEmpty {
                        RemoteImage(url: img)
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 130)
                            .padding(8)
                    } else {
                        Image("spice_monk_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 90, maxHeight: 90)
                            .frame(maxWidth: .infinity, maxHeight: 130)
                    }

                    // Pink Discount Pill Badge
                    if let discount = product.discountPercentage, !discount.isEmpty, discount != "0" {
                        Text("\(discount)% OFF")
                            .font(.appFont(size: 9.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#C8322B"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Color(hex: "#FDECEB"))
                            .cornerRadius(4)
                            .padding(6)
                    }
                }
                .frame(height: 140)
            }
            .buttonStyle(.plain)

            // Product Name
            Text(product.name ?? "Spice Powder")
                .font(.appFont(size: 13.5, weight: .heavy))
                .foregroundColor(Color.spiceInk)
                .lineLimit(1)
                .padding(.top, 2)

            // Unit (e.g. 100 gms)
            Text(product.unit ?? "100 gms")
                .font(.appFont(size: 11.5, weight: .medium))
                .foregroundColor(Color.spiceMuted)

            // Price & Strikethrough MRP
            HStack(spacing: 5) {
                Text("₹\(product.price ?? "80.00")")
                    .font(.appFont(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)

                if let mrp = product.mrp, !mrp.isEmpty {
                    Text("₹\(mrp)")
                        .font(.appFont(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.spiceMuted)
                        .strikethrough()
                }
            }

            // Stock Status
            Text(product.inStock == false ? "Out of stock" : "In stock")
                .font(.appFont(size: 11.5, weight: .medium))
                .foregroundColor(product.inStock == false ? Color(hex: "#C8322B") : Color.spiceMuted)
                .padding(.bottom, 2)

            // Full-Width ADD / Stepper Button
            Button(action: {
                selectedPackSizeProduct = product
            }) {
                if inCartCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.appFont(size: 10, weight: .black))
                        Text("\(inCartCount) in Cart")
                            .font(.appFont(size: 12, weight: .heavy))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Color.spicePrimary)
                    .cornerRadius(8)
                } else {
                    Text("ADD")
                        .font(.appFont(size: 12, weight: .heavy))
                        .foregroundColor(Color(hex: "#167444"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Color(hex: "#EBF7EE"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#D2EBD9"), lineWidth: 1)
                        )
                }
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Floating Bottom Cart Bar
    @ViewBuilder
    private var floatingCartBar: some View {
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
                let list = response.dataPage?.products ?? []
                self.products = list
                for prod in list {
                    if let pId = prod.id {
                        if let avl = prod.availableQuantity {
                            CartManager.shared.registerStock(productId: pId, stock: avl)
                        }
                        if let variants = prod.variants {
                            for v in variants {
                                if let vAvl = v.availableQuantity {
                                    CartManager.shared.registerStock(productId: pId, variantId: v.id, variantName: v.unit, stock: vAvl)
                                }
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}

#Preview {
    NavigationStack {
        ProductListingView(brandName: "Spice Monk", categoryName: "Blended Spices", brandId: 1, categoryId: 1)
    }
}
