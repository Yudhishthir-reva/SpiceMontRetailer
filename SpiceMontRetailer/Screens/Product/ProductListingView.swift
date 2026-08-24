//
//  ProductListingView.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

struct ProductListingView: View {
    var brandName: String = "Brand"
    var categoryName: String = "Category"
    var brandId: Int? = nil
    var categoryId: Int? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "Admin Priority"
    @ObservedObject private var cartManager = CartManager.shared
    @State private var showCart: Bool = false
    @State private var selectedProduct: Product? = nil

    @State private var products: [Product] = []
    @State private var isLoading: Bool = false
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let filterChips = ["Admin Priority", "Best Selling", "Price ↑", "Price ↓", "Discount"]
    private let productService = ProductServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var filteredProducts: [Product] {
        var list = products
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            list = list.filter {
                ($0.name?.localizedCaseInsensitiveContains(searchText) == true) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) == true)
            }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(categoryName)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                    Text("\(brandName) · Step 3 of 3")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }

                Spacer()

                Button(action: { showCart = true }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 17))
                            .foregroundColor(Color.spiceInk)
                            .padding(6)

                        if cartManager.itemCount > 0 {
                            Text("\(cartManager.itemCount)")
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.spicePrimary)
                                .clipShape(Capsule())
                                .offset(x: 4, y: -2)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

            // Search Bar & Filter Chips
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.spiceMuted)
                        .font(.system(size: 13, weight: .semibold))
                    TextField("Search in \(categoryName)", text: $searchText)
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))

                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(filterChips, id: \.self) { chip in
                            Button(action: { selectedFilter = chip }) {
                                Text(chip)
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(selectedFilter == chip ? Color.spicePrimary : Color.white)
                                    .foregroundColor(selectedFilter == chip ? .white : Color.spiceInk)
                                    .cornerRadius(20)
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(selectedFilter == chip ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white)
            .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

            if isLoading && products.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(1...6, id: \.self) { _ in
                            SpiceSkeletonBox(height: 220, cornerRadius: 14)
                        }
                    }
                    .padding(16)
                }
                .background(Color.spiceBackground)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(filteredProducts.count) products available")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.spiceMuted)

                        if filteredProducts.isEmpty {
                            SpiceEmptyStateView(
                                title: "No Products Found",
                                message: "No products available in this category.",
                                buttonTitle: "Refresh"
                            ) {
                                loadProducts()
                            }
                            .padding(.top, 30)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                ForEach(filteredProducts) { item in
                                    productGridCell(item)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    loadProducts()
                }
                .background(Color.spiceBackground)
            }

            // Bottom Sticky Cart Bar
            if cartManager.itemCount > 0 {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(cartManager.itemCount) items in cart")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.spiceMuted)
                            Text(cartManager.subtotal.priceLabel)
                                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                                .foregroundColor(Color.spiceInk)
                        }
                        Spacer()
                        Button(action: { showCart = true }) {
                            HStack(spacing: 6) {
                                Text("View Cart")
                                    .font(.system(size: 13, weight: .heavy))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(Color.spicePrimary)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white)
                }
            }
        }
        .onAppear {
            loadProducts()
        }
        .sheet(item: $selectedProduct) { product in
            ProductDetailModalView(product: product)
        }
        .sheet(isPresented: $showCart) {
            NavigationStack { CartScreen() }
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

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
                    isShowToast = true
                }
            } receiveValue: { response in
                self.products = response.dataPage?.products ?? []
            }
            .store(in: &cancellables)
    }

    // MARK: - Product Grid Cell
    private func productGridCell(_ item: Product) -> some View {
        let quantityInCart = cartManager.quantity(for: item)

        return SpiceCard(padding: 10) {
            VStack(alignment: .leading, spacing: 6) {
                // Product Image
                Button(action: { selectedProduct = item }) {
                    ZStack(alignment: .topTrailing) {
                        if let img = item.image, !img.isEmpty {
                            RemoteImage(url: img)
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(colors: [Color(hex: "#B8702F"), Color(hex: "#6E3A15")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 100)
                                .overlay(
                                    Text(item.name?.prefix(4).uppercased() ?? "SPICE")
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundColor(.white)
                                )
                        }

                        if let disc = item.discountPercentage, Double(disc) ?? 0 > 0 {
                            Text("\(disc)% off")
                                .font(.system(size: 8.5, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.spiceDue)
                                .clipShape(Capsule())
                                .padding(4)
                        }
                    }
                }
                .buttonStyle(.plain)

                Text(item.name ?? "Product")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.spiceInk)
                    .lineLimit(1)

                if let unit = item.unit, !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.spiceMuted)
                }

                // Pricing
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(item.price?.priceLabel ?? "₹0")
                        .font(.system(size: 13.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)

                    if let mrp = item.mrp, Double(mrp) ?? 0 > (Double(item.price ?? "0") ?? 0) {
                        Text(mrp.priceLabel)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Color.spiceMuted)
                            .strikethrough()
                    }
                }

                // Add to Cart / Stepper
                if quantityInCart == 0 {
                    Button(action: {
                        cartManager.add(product: item)
                    }) {
                        HStack {
                            Text("ADD")
                                .font(.system(size: 11.5, weight: .heavy))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color.spicePrimary)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                } else {
                    HStack {
                        Button(action: {
                            cartManager.decrement(product: item)
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.spiceInk)
                                .frame(width: 28, height: 32)
                        }

                        Text("\(quantityInCart)")
                            .font(.system(size: 12.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.spiceInk)
                            .frame(maxWidth: .infinity)

                        Button(action: {
                            cartManager.increment(product: item)
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.spiceInk)
                                .frame(width: 28, height: 32)
                        }
                    }
                    .background(Color.spiceBackground)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.spiceCardBorder, lineWidth: 1))
                }
            }
        }
    }
}

// MARK: - Product Detail Modal View
struct ProductDetailModalView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cartManager = CartManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Modal Top Bar
            HStack {
                Text(product.name ?? "Product Details")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Color.spiceInk)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.spiceMuted)
                }
            }
            .padding(16)
            .background(Color.white)
            .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let img = product.image, !img.isEmpty {
                        RemoteImage(url: img)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Price & Stock
                    SpiceCard {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Retailer Wholesale Price")
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(Color.spiceMuted)
                                Spacer()
                                Text(product.price?.priceLabel ?? "₹0")
                                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color.spiceInk)
                            }
                            Divider()
                            HStack {
                                Text("MRP (Reference)")
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(Color.spiceMuted)
                                Spacer()
                                Text(product.mrp?.priceLabel ?? "—")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(Color.spiceMuted)
                                    .strikethrough()
                            }
                        }
                    }

                    if let desc = product.description, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.system(size: 12.5, weight: .heavy))
                                .foregroundColor(Color.spiceInk)
                            Text(desc)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                                .lineSpacing(3)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.spiceBackground)

            // Bottom Add to Cart
            VStack(spacing: 0) {
                Divider()
                HStack {
                    SpicePrimaryButton(title: "Add to Cart") {
                        cartManager.add(product: product)
                        dismiss()
                    }
                }
                .padding(16)
                .background(Color.white)
            }
        }
    }
}
