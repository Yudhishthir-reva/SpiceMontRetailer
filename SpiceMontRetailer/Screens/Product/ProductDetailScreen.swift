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

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if let product = viewModel.product {
                    productContent(product)
                }
            }
            .background(AppTheme.homeCanvas)

            // Bottom add-to-cart bar
            if let product = viewModel.product {
                bottomBar(product)
            }
        }
        .spiceNavigationBar(title: viewModel.product?.name ?? "Product")
        .onAppear { viewModel.load(productId: productId) }
        .toast(isPresenting: $viewModel.isShowToast, duration: 1.8, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: viewModel.toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Content

    @ViewBuilder
    private func productContent(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image carousel
            imageCarousel(product)

            VStack(alignment: .leading, spacing: 12) {
                // Badges
                HStack(spacing: 8) {
                    if product.isNew == true {
                        Text("NEW")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.newBadgeText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.newBadgeBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    if product.hasDiscount {
                        Text(product.discountText)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.discountBadge)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    if product.inStock == false {
                        Text("OUT OF STOCK")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "DC2626"))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                // Name
                Text(product.name ?? "")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                // Unit
                if let unit = product.unit, !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.accentSoft)
                        .clipShape(Capsule())
                }

                // Price
                HStack(alignment: .bottom, spacing: 8) {
                    Text(product.displayPrice)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppTheme.brandGreen)

                    if product.hasDiscount {
                        Text(product.displayMRP)
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.textMuted)
                            .strikethrough()

                        Text(product.discountText)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.brandGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.saveBadgeFill)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                // Variants
                if let variants = product.variants, !variants.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available Variants")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(variants) { variant in
                                    VStack(spacing: 2) {
                                        Text(variant.unit ?? "")
                                            .font(.system(size: 13, weight: .medium))
                                        Text(variant.price?.priceLabel ?? "")
                                            .font(.system(size: 12))
                                            .foregroundStyle(AppTheme.brandGreen)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.accentSoft)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(AppTheme.fieldBorder, lineWidth: 1)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                Divider()
                    .padding(.vertical, 8)

                // Description
                if let desc = product.description, !desc.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(desc)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineSpacing(4)
                    }
                }

                // Category & Brand
                HStack(spacing: 16) {
                    if let cat = product.categoryName, !cat.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 11))
                            Text(cat)
                                .font(.system(size: 13))
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                    if let brand = product.brandName, !brand.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 11))
                            Text(brand)
                                .font(.system(size: 13))
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)

            // Related products
            if !viewModel.relatedProducts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Related Products")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.relatedProducts) { rp in
                                NavigationLink {
                                    ProductDetailScreen(productId: rp.id ?? 0)
                                } label: {
                                    relatedCard(rp)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
                .background(AppTheme.categoryPanel)
            }

            Color.clear.frame(height: 90)
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

        return TabView {
            ForEach(Array(imageURLs.enumerated()), id: \.offset) { _, url in
                RemoteImage(url: url, contentMode: .fit)
                    .background(AppTheme.imageTile)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: 300)
        .background(AppTheme.imageTile)
    }

    // MARK: - Related Card

    private func relatedCard(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            RemoteImage(url: product.image)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(product.name ?? "")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)

            Text(product.displayPrice)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.brandGreen)
        }
        .frame(width: 120)
    }

    // MARK: - Bottom Bar

    private func bottomBar(_ product: Product) -> some View {
        let qty = cartManager.quantityForProduct(productId)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.displayPrice)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                if product.hasDiscount {
                    Text(product.displayMRP)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textMuted)
                        .strikethrough()
                }
            }

            Spacer()

            if qty > 0 {
                HStack(spacing: 0) {
                    Button {
                        if qty <= 1 {
                            cartManager.removeFromCart(productId: productId)
                        } else {
                            cartManager.updateQuantity(productId: productId, quantity: qty - 1)
                        }
                    } label: {
                        Image(systemName: qty <= 1 ? "trash" : "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 44)
                    }

                    Text("\(qty)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 34)

                    Button {
                        cartManager.updateQuantity(productId: productId, quantity: qty + 1)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 44)
                    }
                }
                .background(AppTheme.brandGreen)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Button {
                    cartManager.addToCart(productId: productId)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.badge.plus")
                        Text("Add to Cart")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 48)
                    .background(AppTheme.ctaGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(product.inStock == false)
                .opacity(product.inStock == false ? 0.5 : 1)
            }
        }
        .padding(16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 8, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
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
