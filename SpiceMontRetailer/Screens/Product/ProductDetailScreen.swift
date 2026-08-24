//
//  ProductDetailScreen.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI
import Combine

struct ProductDetailScreen: View {

    let productId: Int

    @StateObject private var viewModel = ProductDetailViewModel()
    @ObservedObject private var cartManager = CartManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCart: Bool = false
    @State private var selectedQty: Int = 1

    var body: some View {
        VStack(spacing: 0) {
            // B2B Top Bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.product?.name ?? "Product Detail")
                        .font(.system(size: 14.5, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                        .lineLimit(1)
                    if let brand = viewModel.product?.brandName, !brand.isEmpty {
                        Text(brand)
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(Color.spiceMuted)
                    }
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

            ZStack(alignment: .bottom) {
                ScrollView(.vertical, showsIndicators: false) {
                    if viewModel.isLoading {
                        VStack(spacing: 12) {
                            SpiceSkeletonBox(height: 240, cornerRadius: 0)
                            SpiceSkeletonBox(height: 120, cornerRadius: 14)
                            SpiceSkeletonBox(height: 160, cornerRadius: 14)
                        }
                        .padding(16)
                    } else if let product = viewModel.product {
                        VStack(spacing: 14) {
                            // Image Carousel
                            imageCarousel(product)

                            VStack(spacing: 12) {
                                // Title & Wholesale Pricing Card
                                wholesalePricingCard(product)

                                // Active Trade Scheme Banner
                                tradeSchemeBanner

                                // Packaging & Logistics Specs Card
                                packagingSpecsCard(product)

                                // Description Card
                                if let desc = product.description, !desc.isEmpty {
                                    SpiceCard {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Product Description")
                                                .font(.system(size: 12.5, weight: .heavy))
                                                .foregroundColor(Color.spiceInk)
                                            Divider()
                                            Text(desc)
                                                .font(.system(size: 11.5, weight: .medium))
                                                .foregroundColor(Color.spiceMuted)
                                                .lineSpacing(3)
                                        }
                                    }
                                }

                                // Related Products
                                if !viewModel.relatedProducts.isEmpty {
                                    relatedProductsSection
                                }

                                Spacer(minLength: 80)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .background(Color.spiceBackground)

                // Sticky Bottom Wholesale Action Bar
                if let product = viewModel.product {
                    bottomActionBar(product)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCart) {
            NavigationStack { CartScreen() }
        }
        .onAppear {
            viewModel.load(productId: productId)
        }
        .toast(isPresenting: $viewModel.isShowToast, duration: 1.8, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: viewModel.toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Wholesale Pricing Card
    private func wholesalePricingCard(_ product: Product) -> some View {
        SpiceCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name ?? "Product")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        if let unit = product.unit, !unit.isEmpty {
                            Text("Pack Size: \(unit)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.spiceMuted)
                        }
                    }

                    Spacer()

                    if product.inStock == false {
                        SpiceStatusBadge(status: "OUT OF STOCK")
                    } else {
                        SpiceStatusBadge(status: "IN STOCK")
                    }
                }

                Divider()

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(product.displayPrice)
                        .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spicePrimary)

                    if product.hasDiscount {
                        Text(product.displayMRP)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.spiceMuted)
                            .strikethrough()

                        Text(product.discountText)
                            .font(.system(size: 10.5, weight: .heavy))
                            .foregroundColor(Color.spicePrimaryDark)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.spicePrimaryWash)
                            .cornerRadius(4)
                    }

                    Spacer()

                    Text("Wholesale Rate")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(Color.spiceMuted)
                }

                // Retailer Margin Callout
                HStack {
                    Image(systemName: "percent")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.spicePrimary)

                    Text("Retailer Margin: ~18.5% on MRP")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(Color.spicePrimaryDark)

                    Spacer()
                }
                .padding(8)
                .background(Color.spicePrimaryWash)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Trade Scheme Banner
    private var tradeSchemeBanner: some View {
        SpiceCard(backgroundColor: Color(hex: "#FFFBEB"), borderColor: Color(hex: "#FDE68A")) {
            HStack(spacing: 10) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#D97706"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("ACTIVE TRADE SCHEME")
                        .font(.system(size: 9.5, weight: .heavy))
                        .foregroundColor(Color(hex: "#B45309"))
                    Text("Order 10+ packs to unlock 5% extra cash discount or free sample units.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.spiceInk)
                }
                Spacer()
            }
        }
    }

    // MARK: - Packaging & Specs Card
    private func packagingSpecsCard(_ product: Product) -> some View {
        SpiceCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Wholesale Specifications")
                    .font(.system(size: 12.5, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Divider()

                SpiceKVRow(key: "Brand", value: product.brandName ?? "SpiceMonk")
                SpiceKVRow(key: "Category", value: product.categoryName ?? "Spices")
                SpiceKVRow(key: "Case Pack", value: "12 Units / Master Box")
                SpiceKVRow(key: "HSN Code", value: "0910 99 90", isMonoValue: true)
                SpiceKVRow(key: "GST Rate", value: "5.0% (Wholesale ELT)", isMonoValue: true)
                SpiceKVRow(key: "Minimum Order", value: "1 Pack (MOQ)")
            }
        }
    }

    // MARK: - Related Products Section
    private var relatedProductsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Frequently Ordered Together")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.relatedProducts) { rp in
                        NavigationLink(destination: ProductDetailScreen(productId: rp.id ?? 0)) {
                            SpiceCard(padding: 10) {
                                VStack(alignment: .leading, spacing: 6) {
                                    if let img = rp.image, !img.isEmpty {
                                        RemoteImage(url: img)
                                            .frame(width: 100, height: 80)
                                            .cornerRadius(6)
                                    } else {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.spiceLightGray)
                                            .frame(width: 100, height: 80)
                                    }

                                    Text(rp.name ?? "")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Color.spiceInk)
                                        .lineLimit(1)

                                    Text(rp.displayPrice)
                                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                        .foregroundColor(Color.spicePrimary)
                                }
                                .frame(width: 100)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Image Carousel
    private func imageCarousel(_ product: Product) -> some View {
        let imageURLs: [String] = {
            if let imgs = product.images, !imgs.isEmpty {
                return imgs.compactMap { $0.image }
            }
            if let img = product.image { return [img] }
            return []
        }()

        return Group {
            if !imageURLs.isEmpty {
                TabView {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { _, url in
                        RemoteImage(url: url)
                            .frame(maxWidth: .infinity, maxHeight: 240)
                            .background(Color.white)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 240)
                .background(Color.white)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [Color.spicePrimaryWash, Color.white], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 180)
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundColor(Color.spicePrimary.opacity(0.6))
                            Text("SpiceMonk Wholesale")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.spiceMuted)
                        }
                    )
            }
        }
    }

    // MARK: - Bottom Action Bar
    private func bottomActionBar(_ product: Product) -> some View {
        let inCartQty = cartManager.quantityForProduct(productId)

        return VStack(spacing: 0) {
            Divider()

            HStack(spacing: 14) {
                // Quick Quantity Stepper
                HStack(spacing: 0) {
                    Button(action: {
                        if inCartQty > 0 {
                            if inCartQty <= 1 {
                                cartManager.removeFromCart(productId: productId)
                            } else {
                                cartManager.updateQuantity(productId: productId, quantity: inCartQty - 1)
                            }
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(inCartQty > 0 ? Color.spiceInk : Color.spiceMuted.opacity(0.4))
                            .frame(width: 38, height: 42)
                    }
                    .disabled(inCartQty == 0)

                    Text("\(max(1, inCartQty))")
                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)
                        .frame(width: 36)

                    Button(action: {
                        if inCartQty == 0 {
                            cartManager.addToCart(productId: productId)
                        } else {
                            cartManager.updateQuantity(productId: productId, quantity: inCartQty + 1)
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.spiceInk)
                            .frame(width: 38, height: 42)
                    }
                }
                .background(Color.spiceLightGray)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))

                // Primary Add to Cart Button
                if inCartQty > 0 {
                    SpicePrimaryButton(title: "View Cart (\(inCartQty))", height: 46) {
                        showCart = true
                    }
                } else {
                    SpicePrimaryButton(title: "+ Add to Cart", height: 46, isEnabled: product.inStock != false) {
                        cartManager.addToCart(productId: productId)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
    }
}

// MARK: - ViewModel

class ProductDetailViewModel: ObservableObject {

    @Published var product: Product?
    @Published var relatedProducts: [Product] = []
    @Published var isLoading = true
    @Published var isShowToast = false
    @Published var toastMessage = ""

    private let service = ProductServiceManager()
    private var cancellables = Set<AnyCancellable>()

    func load(productId: Int) {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader
        let params: [String: Any] = ["product_id": productId]

        service.fetchDetail(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    self?.isShowToast = true
                }
            } receiveValue: { [weak self] response in
                self?.product = response.product
                self?.loadRelated(productId: productId)
            }
            .store(in: &cancellables)
    }

    private func loadRelated(productId: Int) {
        let headers = UserDefaultManager.shared.authHeader
        let params: [String: Any] = ["product_id": productId]

        service.fetchRelated(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { _ in }
            receiveValue: { [weak self] response in
                self?.relatedProducts = response.products ?? []
            }
            .store(in: &cancellables)
    }
}

#Preview {
    NavigationStack {
        ProductDetailScreen(productId: 1)
    }
}
