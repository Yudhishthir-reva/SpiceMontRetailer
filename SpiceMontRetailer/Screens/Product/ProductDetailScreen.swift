//
//  ProductDetailScreen.swift
//  SpiceMontRetailer
//
//  Created on 23/08/26.
//

import SwiftUI
import Combine

struct ProductDetailScreen: View {
    let productId: Int
    var initialProduct: Product? = nil

    @StateObject private var viewModel = ProductDetailViewModel()
    @ObservedObject private var cartManager = CartManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showCart: Bool = false
    @State private var kgValues: [String: String] = [:]
    @State private var pktValues: [String: String] = [:]
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private func variantKey(variant: ProductVariant, index: Int) -> String {
        let vId = variant.id ?? (index + 1)
        let unit = variant.unit ?? "\(index)"
        return "\(vId)_\(unit)"
    }

    var displayProduct: Product? {
        viewModel.product ?? initialProduct
    }

    var variants: [ProductVariant] {
        guard let prod = displayProduct else { return [] }
        if let v = prod.variants, !v.isEmpty {
            return v
        }
        if let singleUnit = prod.unit, !singleUnit.isEmpty {
            return [
                ProductVariant(
                    id: prod.id ?? productId,
                    unit: singleUnit,
                    price: prod.price,
                    mrp: prod.mrp,
                    gst: "5%",
                    availableQuantity: 100,
                    minOrderQuantity: 1
                )
            ]
        }
        return []
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if let prod = displayProduct {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            // MARK: - Product Hero Image Card
                            heroImageBox(product: prod)

                            // MARK: - Product Title & Subtitle
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prod.name ?? "")
                                    .font(.appFont(size: 20, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)

                                let brand = prod.brandName ?? "Spice Monk"
                                let category = prod.categoryName ?? "Blended Spices"
                                Text("\(brand) · \(category)")
                                    .font(.appFont(size: 13, weight: .medium))
                                    .foregroundColor(Color.spiceMuted)
                            }
                            .padding(.top, 2)

                            // MARK: - Pack Size Section
                            if !variants.isEmpty {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("Pack Size")
                                        .font(.appFont(size: 14.5, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)

                                    VStack(spacing: 16) {
                                        ForEach(Array(variants.enumerated()), id: \.offset) { index, variant in
                                            variantItemView(variant: variant, index: index, product: prod)
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }

                            // MARK: - Description Card
                            if let desc = prod.description, !desc.isEmpty {
                                descriptionCard(description: desc)
                            }

                            // MARK: - Specifications Card
                            specificationsCard(product: prod)

                            Spacer(minLength: 90)
                        }
                        .padding(16)
                    }
                } else if viewModel.isLoading {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                            .tint(Color.spicePrimary)
                        Text("Loading product details...")
                            .font(.appFont(size: 13, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        Spacer()
                        SpiceEmptyStateView(
                            title: "Product Not Found",
                            message: "This product details are currently unavailable.",
                            buttonTitle: "Go Back"
                        ) {
                            dismiss()
                        }
                        Spacer()
                    }
                }
            }

            // MARK: - Floating Bottom Cart Bar
            floatingCartBar
        }
        .navigationTitle(displayProduct?.name ?? "Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showCart) {
            NavigationStack { CartScreen() }
        }
        .onAppear {
            viewModel.load(productId: productId)
            populateExistingQuantities()
            cartManager.fetchCart()
        }
        .onReceive(viewModel.$product) { newProd in
            if newProd != nil {
                populateExistingQuantities()
            }
        }
        .onReceive(cartManager.$items) { newItems in
            if newItems.isEmpty {
                pktValues.removeAll()
                kgValues.removeAll()
            }
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
        .toast(isPresenting: $viewModel.isShowToast, duration: 1.8, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: viewModel.toastMessage)
        }, onTap: nil, completion: nil)
    }

    private func populateExistingQuantities() {
        guard let pId = displayProduct?.id ?? productId as Int? else { return }
        for (index, variant) in variants.enumerated() {
            let key = variantKey(variant: variant, index: index)
            let count = cartManager.quantityForProduct(pId, variantId: variant.id, variantName: variant.unit)
            if count > 0 {
                pktValues[key] = "\(count)"
                kgValues[key] = UnitConverter.pktToKg(pkt: count, unit: variant.unit)
            }
        }
    }

    // MARK: - Hero Image Box
    private func heroImageBox(product: Product) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#F8F9FA"))

            if let img = product.image, !img.isEmpty {
                RemoteImage(url: img)
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .padding(16)
            } else {
                Image("spice_monk_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(24)
            }
        }
        .frame(height: 300)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Variant Item View
    @ViewBuilder
    private func variantItemView(variant: ProductVariant, index: Int, product: Product) -> some View {
        let key = variantKey(variant: variant, index: index)
        let isUnavailable = (variant.availableQuantity ?? 100) == 0
        let pId = product.id ?? productId

        VStack(alignment: .leading, spacing: 6) {
            // Row 1: Unit Name (Left) + Stock Status (Right)
            HStack {
                Text(variant.unit ?? "100 gms")
                    .font(.appFont(size: 15, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Spacer()

                Text(isUnavailable ? "Out of stock" : "In stock")
                    .font(.appFont(size: 12.5, weight: .bold))
                    .foregroundColor(isUnavailable ? Color(hex: "#C8322B") : Color(hex: "#167E46"))
            }

            // Row 2: Price & Strikethrough MRP
            HStack(spacing: 6) {
                Text("₹\(variant.price ?? "0.00")")
                    .font(.appFont(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)

                if let mrp = variant.mrp, !mrp.isEmpty {
                    Text("₹\(mrp)")
                        .font(.appFont(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.spiceMuted)
                        .strikethrough()
                }
            }

            // Row 3: "Order" Label
            Text("Order")
                .font(.appFont(size: 12, weight: .medium))
                .foregroundColor(Color.spiceMuted)
                .padding(.top, 2)

            // Row 4: Kg & Pkt Inputs Side by Side
            HStack(spacing: 12) {
                // Kg Input Field
                HStack {
                    TextField("0", text: Binding(
                        get: { kgValues[key] ?? "" },
                        set: { newKg in
                            let sanitizedKg = newKg.sanitizedDecimalQuantity(maxDecimalPlaces: 1)
                            if sanitizedKg.hasSuffix(".") {
                                kgValues[key] = sanitizedKg
                            } else if let kgVal = Double(sanitizedKg), kgVal > 0 {
                                var calculatedPkt = UnitConverter.kgToPkt(kg: kgVal, unit: variant.unit)
                                if let avl = variant.availableQuantity, calculatedPkt > avl {
                                    calculatedPkt = avl
                                    toastMessage = "Only \(avl) units available in stock."
                                    isShowToast = true
                                }
                                pktValues[key] = calculatedPkt > 0 ? "\(calculatedPkt)" : ""
                                kgValues[key] = calculatedPkt > 0 ? UnitConverter.pktToKg(pkt: calculatedPkt, unit: variant.unit) : sanitizedKg

                                if !isUnavailable {
                                    cartManager.setQuantity(
                                        productId: pId,
                                        variantId: variant.id,
                                        variantName: variant.unit,
                                        quantity: calculatedPkt,
                                        product: product,
                                        price: variant.price,
                                        availableQuantity: variant.availableQuantity
                                    )
                                }
                            } else if sanitizedKg.isEmpty || sanitizedKg == "0" || sanitizedKg == "0." {
                                kgValues[key] = sanitizedKg.isEmpty ? "" : sanitizedKg
                                pktValues[key] = ""
                                cartManager.setQuantity(
                                    productId: pId,
                                    variantId: variant.id,
                                    variantName: variant.unit,
                                    quantity: 0,
                                    product: product,
                                    price: variant.price
                                )
                            } else {
                                kgValues[key] = sanitizedKg
                            }
                        }
                    ))
                    .font(.appFont(size: 13.5, weight: .bold))
                    .foregroundColor(Color.spiceInk)
                    .keyboardType(.decimalPad)
                    .disabled(isUnavailable)

                    Text("Kg")
                        .font(.appFont(size: 12.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color(hex: "#F4F6F4"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.spiceCardBorder.opacity(0.5), lineWidth: 1)
                )

                // Pkt Input Field
                HStack {
                    TextField("0", text: Binding(
                        get: { pktValues[key] ?? "" },
                        set: { newPkt in
                            let sanitizedPkt = newPkt.sanitizedIntegerQuantity(maxDigits: 5)
                            pktValues[key] = sanitizedPkt
                            if let pktVal = Int(sanitizedPkt), pktVal > 0 {
                                var finalPkt = pktVal
                                if let avl = variant.availableQuantity, finalPkt > avl {
                                    finalPkt = avl
                                    toastMessage = "Only \(avl) units available in stock."
                                    isShowToast = true
                                    pktValues[key] = "\(finalPkt)"
                                    kgValues[key] = UnitConverter.pktToKg(pkt: finalPkt, unit: variant.unit)
                                } else {
                                    let calculatedKg = UnitConverter.pktToKg(pkt: finalPkt, unit: variant.unit)
                                    kgValues[key] = calculatedKg
                                }

                                if !isUnavailable {
                                    cartManager.setQuantity(
                                        productId: pId,
                                        variantId: variant.id,
                                        variantName: variant.unit,
                                        quantity: finalPkt,
                                        product: product,
                                        price: variant.price,
                                        availableQuantity: variant.availableQuantity
                                    )
                                }
                            } else if sanitizedPkt.isEmpty || sanitizedPkt == "0" {
                                kgValues[key] = ""
                                cartManager.setQuantity(
                                    productId: pId,
                                    variantId: variant.id,
                                    variantName: variant.unit,
                                    quantity: 0,
                                    product: product,
                                    price: variant.price
                                )
                            }
                        }
                    ))
                    .font(.appFont(size: 13.5, weight: .bold))
                    .foregroundColor(Color.spiceInk)
                    .keyboardType(.numberPad)
                    .disabled(isUnavailable)

                    Text("Pkt")
                        .font(.appFont(size: 12.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color(hex: "#F4F6F4"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.spiceCardBorder.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Description Card
    private func descriptionCard(description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.appFont(size: 15, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            Text(description)
                .font(.appFont(size: 13, weight: .medium))
                .foregroundColor(Color.spiceInk.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Specifications Card
    private func specificationsCard(product: Product) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Specifications")
                .font(.appFont(size: 15, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            specRow(key: "Pack Size", value: variants.first?.unit ?? product.unit ?? "100 gms")
            specRow(key: "GST", value: variants.first?.gst ?? "5%")
            specRow(key: "Minimum Order", value: "\(variants.first?.minOrderQuantity ?? 1) units")
            if let hsn = product.hsnCode, !hsn.isEmpty {
                specRow(key: "HSN Code", value: hsn, isMono: true)
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

    private func specRow(key: String, value: String, isMono: Bool = false) -> some View {
        HStack {
            Text(key)
                .font(.appFont(size: 13, weight: .medium))
                .foregroundColor(Color.spiceMuted)

            Spacer()

            Text(value)
                .font(
                    isMono ?
                        .appFont(size: 13, weight: .heavy, design: .monospaced) :
                        .appFont(size: 13, weight: .bold)
                )
                .foregroundColor(Color.spiceInk)
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
}

#Preview {
    NavigationStack {
        ProductDetailScreen(productId: 1)
    }
}
