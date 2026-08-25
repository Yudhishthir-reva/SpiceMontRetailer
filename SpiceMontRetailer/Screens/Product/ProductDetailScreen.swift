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
    @State private var selectedVariantIndex: Int = 0
    @State private var kgValues: [String: String] = [:]
    @State private var pktValues: [String: String] = [:]
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private func variantKey(variant: ProductVariant, index: Int) -> String {
        let vId = variant.id ?? (index + 1)
        let unit = variant.unit ?? "\(index)"
        return "\(vId)_\(unit)"
    }

    var displayProduct: Product {
        viewModel.product ?? initialProduct ?? sampleProduct
    }

    var variants: [ProductVariant] {
        if let v = displayProduct.variants, !v.isEmpty {
            return v
        }
        if let singleUnit = displayProduct.unit, !singleUnit.isEmpty {
            return [
                ProductVariant(
                    id: displayProduct.id ?? productId,
                    unit: singleUnit,
                    price: displayProduct.price,
                    mrp: displayProduct.mrp,
                    availableQuantity: 100
                )
            ]
        }
        return []
    }

    var selectedVariant: ProductVariant? {
        if variants.indices.contains(selectedVariantIndex) {
            return variants[selectedVariantIndex]
        }
        return variants.first
    }

    var currentPrice: String {
        selectedVariant?.price ?? displayProduct.price ?? "26.00"
    }

    var currentMRP: String {
        selectedVariant?.mrp ?? displayProduct.mrp ?? "52.00"
    }

    var currentUnit: String {
        selectedVariant?.unit ?? displayProduct.unit ?? "200 gms"
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
                            .padding(6)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text((displayProduct.name ?? "PRODUCT").uppercased())
                            .font(.system(size: 16.5, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                            .lineLimit(1)

                        Text(displayProduct.brandName ?? "Spice Monk")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }

                    Spacer()

                    Button(action: { showCart = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "cart")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color.spiceInk)
                                .padding(6)

                            if cartManager.cartCount > 0 {
                                Text("\(cartManager.cartCount)")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.spicePrimary)
                                    .clipShape(Capsule())
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(Color.white)
                .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // MARK: - Hero Image Box
                        heroImageBox

                        // MARK: - Product Title & Subtitle
                        VStack(alignment: .leading, spacing: 4) {
                            Text((displayProduct.name ?? "PRODUCT").uppercased())
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(Color.spiceInk)

                            Text("\(displayProduct.brandName ?? "Spice Monk") · \((displayProduct.name ?? "").uppercased())")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)

                        // MARK: - Price Card
                        priceCard

                        // MARK: - Pack Size Selector Pills
                        packSizeSelectorPills

                        // MARK: - Variant-Wise Ordering Section
                        variantOrderingSection

                        // MARK: - Stock Status Card
                        stockStatusCard

                        // MARK: - Description Card
                        descriptionCard

                        // MARK: - Specifications Card
                        specificationsCard

                        Spacer(minLength: 90)
                    }
                    .padding(16)
                }
            }

            // MARK: - Floating Bottom Cart Pill Bar
            floatingCartBar
        }
        .navigationBarHidden(true)
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
        let pId = displayProduct.id ?? productId
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
    private var heroImageBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)

            if let img = displayProduct.image, !img.isEmpty {
                RemoteImage(url: img)
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .padding(16)
            } else {
                Image("spice_monk_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .padding(24)
            }
        }
        .frame(height: 260)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Price Card
    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 10) {
                Text("₹\(currentPrice)")
                    .font(.system(size: 24, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)

                if !currentMRP.isEmpty {
                    Text("₹\(currentMRP)")
                        .font(.system(size: 14.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.spiceMuted)
                        .strikethrough()
                }

                if let discount = displayProduct.discountPercentage, !discount.isEmpty, discount != "0" {
                    Text("\(discount)% OFF")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color(hex: "#C8322B"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Color(hex: "#FDECEB"))
                        .cornerRadius(5)
                }

                Spacer()
            }

            Text("Retailer price for \(currentUnit). MRP shown for reference.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.spiceMuted)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Pack Size Selector Pills
    private var packSizeSelectorPills: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Pack Size")
                .font(.system(size: 13.5, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(variants.enumerated()), id: \.offset) { index, variant in
                        let isSelected = selectedVariantIndex == index
                        let unit = variant.unit ?? "200 gms"

                        Button(action: {
                            selectedVariantIndex = index
                        }) {
                            Text(unit)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(isSelected ? .white : Color.spiceInk)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Variant-Wise Ordering Section
    private var variantOrderingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pack Sizes & Quantities")
                .font(.system(size: 14.5, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            VStack(spacing: 12) {
                ForEach(Array(variants.enumerated()), id: \.offset) { index, variant in
                    variantOrderRow(variant: variant, index: index)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Single Variant Order Row
    private func variantOrderRow(variant: ProductVariant, index: Int) -> some View {
        let key = variantKey(variant: variant, index: index)
        let isUnavailable = variant.availableQuantity == 0
        let currentPkt = Int(pktValues[key] ?? "") ?? 0
        let pId = displayProduct.id ?? productId

        return VStack(alignment: .leading, spacing: 10) {
            // Top Row: Unit, Price, and Action (ADD / Stepper)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(variant.unit ?? "100 gms")
                        .font(.system(size: 14.5, weight: .heavy))
                        .foregroundColor(Color.spiceInk)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("₹\(variant.price ?? currentPrice)")
                            .font(.system(size: 13.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.spiceInk)

                        if let mrp = variant.mrp, !mrp.isEmpty {
                            Text("₹\(mrp)")
                                .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.spiceMuted)
                                .strikethrough()
                        }
                    }

                    if isUnavailable {
                        Text("Currently unavailable")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color(hex: "#C8322B"))
                            .padding(.top, 1)
                    }
                }

                Spacer()

                // Action: Disabled / Mint ADD / Green Stepper
                if isUnavailable {
                    Text("ADD")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                        .frame(width: 72, height: 34)
                        .background(Color(hex: "#F3F4F6"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
                        )
                } else if currentPkt == 0 {
                    Button(action: {
                        if let avl = variant.availableQuantity, avl < 1 {
                            toastMessage = "Item is currently out of stock."
                            isShowToast = true
                            return
                        }
                        let pktCount = 1
                        pktValues[key] = "\(pktCount)"
                        kgValues[key] = UnitConverter.pktToKg(pkt: pktCount, unit: variant.unit)
                        cartManager.setQuantity(
                            productId: pId,
                            variantId: variant.id,
                            variantName: variant.unit,
                            quantity: pktCount,
                            product: displayProduct,
                            price: variant.price,
                            availableQuantity: variant.availableQuantity
                        )
                    }) {
                        Text("ADD")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(Color(hex: "#167444"))
                            .frame(width: 72, height: 34)
                            .background(Color(hex: "#EBF7EE"))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#D2EBD9"), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    // Green Stepper Pill
                    HStack(spacing: 8) {
                        Button(action: {
                            if currentPkt <= 1 {
                                pktValues[key] = ""
                                kgValues[key] = ""
                                cartManager.removeProduct(productId: pId, variantId: variant.id, variantName: variant.unit)
                            } else {
                                let newQty = currentPkt - 1
                                pktValues[key] = "\(newQty)"
                                kgValues[key] = UnitConverter.pktToKg(pkt: newQty, unit: variant.unit)
                                cartManager.setQuantity(
                                    productId: pId,
                                    variantId: variant.id,
                                    variantName: variant.unit,
                                    quantity: newQty,
                                    product: displayProduct,
                                    price: variant.price,
                                    availableQuantity: variant.availableQuantity
                                )
                            }
                        }) {
                            Text("−")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 32)
                        }

                        Text("\(currentPkt)")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(minWidth: 20)

                        Button(action: {
                            if let avl = variant.availableQuantity, currentPkt >= avl {
                                toastMessage = "Only \(avl) units available in stock."
                                isShowToast = true
                                return
                            }
                            let newQty = currentPkt + 1
                            pktValues[key] = "\(newQty)"
                            kgValues[key] = UnitConverter.pktToKg(pkt: newQty, unit: variant.unit)
                            cartManager.setQuantity(
                                productId: pId,
                                variantId: variant.id,
                                variantName: variant.unit,
                                quantity: newQty,
                                product: displayProduct,
                                price: variant.price,
                                availableQuantity: variant.availableQuantity
                            )
                        }) {
                            Text("+")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 32)
                        }
                    }
                    .padding(.horizontal, 6)
                    .frame(height: 34)
                    .background(Color.spicePrimary)
                    .cornerRadius(8)
                }
            }

            // Bottom Row: Kg & Pkt Inputs with Live Two-Way Binding & Stock Guard
            HStack(spacing: 12) {
                // Kg Box
                HStack {
                    TextField("0", text: Binding(
                        get: { kgValues[key] ?? "" },
                        set: { newKg in
                            kgValues[key] = newKg
                            if let kgVal = Double(newKg), kgVal > 0 {
                                var calculatedPkt = UnitConverter.kgToPkt(kg: kgVal, unit: variant.unit)
                                if let avl = variant.availableQuantity, calculatedPkt > avl {
                                    calculatedPkt = avl
                                    toastMessage = "Only \(avl) units available in stock."
                                    isShowToast = true
                                }
                                pktValues[key] = calculatedPkt > 0 ? "\(calculatedPkt)" : ""
                                kgValues[key] = calculatedPkt > 0 ? UnitConverter.pktToKg(pkt: calculatedPkt, unit: variant.unit) : newKg

                                if !isUnavailable {
                                    cartManager.setQuantity(
                                        productId: pId,
                                        variantId: variant.id,
                                        variantName: variant.unit,
                                        quantity: calculatedPkt,
                                        product: displayProduct,
                                        price: variant.price,
                                        availableQuantity: variant.availableQuantity
                                    )
                                }
                            } else if newKg.isEmpty || newKg == "0" {
                                pktValues[key] = ""
                                cartManager.setQuantity(
                                    productId: pId,
                                    variantId: variant.id,
                                    variantName: variant.unit,
                                    quantity: 0,
                                    product: displayProduct,
                                    price: variant.price
                                )
                            }
                        }
                    ))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.spiceInk)
                    .keyboardType(.decimalPad)
                    .disabled(isUnavailable)

                    Text("Kg")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Color(hex: "#F3F4F6"))
                .cornerRadius(8)

                // Pkt Box
                HStack {
                    TextField("0", text: Binding(
                        get: { pktValues[key] ?? "" },
                        set: { newPkt in
                            pktValues[key] = newPkt
                            if let pktVal = Int(newPkt), pktVal > 0 {
                                var finalPkt = pktVal
                                if let avl = variant.availableQuantity, finalPkt > avl {
                                    finalPkt = avl
                                    toastMessage = "Only \(avl) units available in stock."
                                    isShowToast = true
                                }
                                pktValues[key] = "\(finalPkt)"
                                let calculatedKg = UnitConverter.pktToKg(pkt: finalPkt, unit: variant.unit)
                                kgValues[key] = calculatedKg

                                if !isUnavailable {
                                    cartManager.setQuantity(
                                        productId: pId,
                                        variantId: variant.id,
                                        variantName: variant.unit,
                                        quantity: finalPkt,
                                        product: displayProduct,
                                        price: variant.price,
                                        availableQuantity: variant.availableQuantity
                                    )
                                }
                            } else if newPkt.isEmpty || newPkt == "0" {
                                kgValues[key] = ""
                                cartManager.setQuantity(
                                    productId: pId,
                                    variantId: variant.id,
                                    variantName: variant.unit,
                                    quantity: 0,
                                    product: displayProduct,
                                    price: variant.price
                                )
                            }
                        }
                    ))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.spiceInk)
                    .keyboardType(.numberPad)
                    .disabled(isUnavailable)

                    Text("Pkt")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Color(hex: "#F3F4F6"))
                .cornerRadius(8)
            }

            if index < variants.count - 1 {
                Divider().background(Color.spiceDivider.opacity(0.6)).padding(.top, 6)
            }
        }
    }

    // MARK: - Stock Status Card
    private var stockStatusCard: some View {
        HStack {
            Text(displayProduct.inStock == false ? "Out of stock" : "In stock")
                .font(.system(size: 13.5, weight: .bold))
                .foregroundColor(displayProduct.inStock == false ? Color(hex: "#C8322B") : Color(hex: "#167444"))

            Spacer()

            Text("Max 97 pkt per order")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#5B8A6E"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: "#EBF7EE"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#D2EBD9"), lineWidth: 1)
        )
    }

    // MARK: - Description Card
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            Text(displayProduct.description ?? (displayProduct.name ?? "PRODUCT").uppercased())
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.spiceInk.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Specifications Card
    private var specificationsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Specifications")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            specRow(key: "Pack Size", value: currentUnit)
            specRow(key: "GST", value: "5%")
            specRow(key: "Minimum Order", value: "1 units")
            specRow(key: "HSN Code", value: displayProduct.hsnCode ?? "09109912", isMono: true)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    private func specRow(key: String, value: String, isMono: Bool = false) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.spiceMuted)

            Spacer()

            Text(value)
                .font(
                    isMono ?
                        .system(size: 13, weight: .heavy, design: .monospaced) :
                        .system(size: 13, weight: .bold)
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

    // Fallback sample product matching reference screenshot
    private var sampleProduct: Product {
        Product(
            id: productId,
            name: "DANA METHI",
            slug: "dana-methi",
            image: "",
            price: "26.00",
            mrp: "52.00",
            discountPercentage: "50",
            unit: "200 gms",
            description: "DANA METHI",
            hsnCode: "09109912",
            inStock: true,
            isNew: false,
            categoryId: 1,
            categoryName: "Spices",
            brandId: 3,
            brandName: "Spice Monk",
            variants: [
                ProductVariant(id: 1, unit: "100 gms", price: "14.00", mrp: "28.00"),
                ProductVariant(id: 2, unit: "200 gms", price: "26.00", mrp: "52.00"),
                ProductVariant(id: 3, unit: "500 gms", price: "62.00", mrp: "124.00"),
                ProductVariant(id: 4, unit: "1 KG", price: "120.00", mrp: "240.00")
            ]
        )
    }
}
